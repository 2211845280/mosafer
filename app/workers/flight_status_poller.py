"""ARQ task that polls flight statuses for upcoming flights.

Runs every 3 minutes via cron, checks flights departing in the next 24 hours,
and creates notifications when status changes are detected.
"""

from __future__ import annotations

import json
from datetime import UTC, datetime, timedelta

import structlog
from sqlalchemy import select

from app.models.flights import Flight
from app.models.reservations import Reservation
from app.services.external.mock_flight_status_service import MockFlightStatusService
from app.services.notification_dispatcher import NotificationDispatcher

logger = structlog.get_logger(__name__)

_status_service = MockFlightStatusService()
_dispatcher = NotificationDispatcher()

_NOTIFICATION_TYPES = {
    "status": "flight_update",
    "departure_gate": "gate_change",
    "delay_minutes": "departure_reminder",
}


def _build_notification(
    change_field: str,
    old_value: str,
    new_value: str,
    carrier_code: str,
    flight_number: str,
) -> tuple[str, str, str]:
    """Return (type, title, body) for a status-change notification."""
    label = f"{carrier_code}{flight_number}"

    if change_field == "status":
        ntype = "flight_update"
        title = f"Status Update – {label}"
        body = f"Flight {label} status changed from {old_value} to {new_value}."
    elif change_field == "departure_gate":
        ntype = "gate_change"
        title = f"Gate Change – {label}"
        body = f"Flight {label} gate changed from {old_value} to {new_value}."
    elif change_field == "delay_minutes":
        ntype = "departure_reminder"
        title = f"Flight Delayed – {label}"
        body = f"Flight {label} delay updated from {old_value} min to {new_value} min."
    else:
        ntype = "flight_update"
        title = f"Flight Update – {label}"
        body = f"Flight {label}: {change_field} changed to {new_value}."

    return ntype, title, body


async def poll_flight_statuses(ctx: dict) -> int:  # noqa: C901
    """Poll statuses for flights departing in the next 24 h.

    Returns the number of flights polled.
    """
    db_factory = ctx.get("db")
    redis = ctx.get("redis")
    if db_factory is None or redis is None:
        logger.error("poll_flight_statuses.missing_context")
        return 0

    now = datetime.now(UTC)
    window_end = now + timedelta(hours=24)

    async with db_factory() as db:
        result = await db.execute(
            select(Flight).where(
                Flight.departure_at >= now,
                Flight.departure_at <= window_end,
            )
        )
        flights = result.scalars().all()

        polled = 0
        for flight in flights:
            cache_key = f"flight:status:{flight.id}"

            prev_raw = await redis.get(cache_key)
            prev_data: dict | None = json.loads(prev_raw) if prev_raw else None

            new_status = await _status_service.get_status(
                carrier_code=flight.carrier_code,
                flight_number=flight.flight_number,
                departure_at=flight.departure_at,
            )
            new_data = new_status.model_dump(mode="json")

            await redis.set(cache_key, json.dumps(new_data), ex=300)
            polled += 1

            if prev_data is None:
                continue

            watch_fields = ["status", "departure_gate", "delay_minutes"]
            changes: list[tuple[str, str, str]] = []
            for field in watch_fields:
                old_val = str(prev_data.get(field, ""))
                new_val = str(new_data.get(field, ""))
                if old_val != new_val:
                    changes.append((field, old_val, new_val))

            if not changes:
                continue

            res_result = await db.execute(
                select(Reservation.user_id).where(Reservation.flight_id == flight.id)
            )
            user_ids = [row[0] for row in res_result.all()]

            for field, old_val, new_val in changes:
                ntype, title, body = _build_notification(
                    field, old_val, new_val, flight.carrier_code, flight.flight_number
                )
                for uid in user_ids:
                    await _dispatcher.dispatch(
                        user_id=uid,
                        event_type=ntype,
                        title=title,
                        body=body,
                        data={"flight_id": str(flight.id), "field": field},
                        db=db,
                    )

            logger.info(
                "poll_flight_statuses.changes_detected",
                flight_id=flight.id,
                changes=[c[0] for c in changes],
                notified_users=len(user_ids),
            )

        await db.commit()

    logger.info("poll_flight_statuses.done", polled=polled)
    return polled
