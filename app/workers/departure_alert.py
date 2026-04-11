"""ARQ cron task that sends departure-time alerts with escalating urgency.

Runs every 30 minutes, checks flights departing in the next 12 hours,
and creates notifications for users who should start preparing to leave.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import structlog
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.airports import Airport
from app.models.flights import Flight
from app.models.reservations import Reservation
from app.models.user_preferences import UserPreference
from app.schemas.departure_plan import TransportMode
from app.services.departure_planner import DeparturePlanner
from app.services.notification_dispatcher import NotificationDispatcher

logger = structlog.get_logger(__name__)

_planner = DeparturePlanner()
_dispatcher = NotificationDispatcher()

_URGENCY = [
    ("departure_urgent", 30, "Leave now!"),
    ("departure_warning", 60, "You should leave soon"),
    ("departure_reminder", 180, "Gentle reminder"),
]


async def check_departure_alerts(ctx: dict) -> int:  # noqa: C901
    """Check upcoming flights and send departure alerts.

    Returns the number of alerts created.
    """
    db_factory = ctx.get("db")
    redis = ctx.get("redis")
    if db_factory is None or redis is None:
        logger.error("check_departure_alerts.missing_context")
        return 0

    now = datetime.now(UTC)
    window_end = now + timedelta(hours=12)
    alerts_created = 0

    async with db_factory() as db:
        result = await db.execute(
            select(Reservation)
            .join(Flight, Reservation.flight_id == Flight.id)
            .where(
                Flight.departure_at >= now,
                Flight.departure_at <= window_end,
                Reservation.status != "canceled",
            )
            .options(selectinload(Reservation.flight))
        )
        reservations = result.scalars().all()

        for reservation in reservations:
            flight = reservation.flight

            airport_result = await db.execute(
                select(Airport).where(Airport.iata_code == flight.origin_iata)
            )
            airport = airport_result.scalar_one_or_none()
            if airport is None or airport.latitude is None or airport.longitude is None:
                continue

            pref_result = await db.execute(
                select(UserPreference).where(UserPreference.user_id == reservation.user_id)
            )
            pref = pref_result.scalar_one_or_none()

            if pref is None or pref.home_lat is None or pref.home_lng is None:
                continue

            if pref.notification_enabled is False:
                continue

            transport = TransportMode(pref.preferred_transport) if pref else TransportMode.driving

            dest_airport_result = await db.execute(
                select(Airport).where(Airport.iata_code == flight.destination_iata)
            )
            dest_airport = dest_airport_result.scalar_one_or_none()
            dest_country = dest_airport.country if dest_airport else "Unknown"

            try:
                plan = await _planner.calculate(
                    user_lat=float(pref.home_lat),
                    user_lng=float(pref.home_lng),
                    airport_lat=float(airport.latitude),
                    airport_lng=float(airport.longitude),
                    airport_country=dest_country,
                    origin_country=airport.country,
                    departure_at=flight.departure_at,
                    transport_mode=transport,
                )
            except Exception:
                logger.exception(
                    "departure_alert.calculation_failed",
                    reservation_id=reservation.id,
                )
                continue

            minutes_until_leave = (plan.leave_at - now).total_seconds() / 60

            for urgency_type, threshold_min, label in _URGENCY:
                if minutes_until_leave > threshold_min:
                    continue

                dedup_key = f"departure_alert:{reservation.id}:{urgency_type}"
                already_sent = await redis.get(dedup_key)
                if already_sent:
                    continue

                flight_label = f"{flight.carrier_code}{flight.flight_number}"
                title = f"{label} – {flight_label}"
                body = (
                    f"Your flight {flight_label} departs at "
                    f"{flight.departure_at.strftime('%H:%M')}. "
                    f"Recommended departure: {plan.leave_at.strftime('%H:%M')} "
                    f"({plan.travel_minutes} min travel, "
                    f"{plan.weather_buffer_minutes} min weather buffer)."
                )

                await _dispatcher.dispatch(
                    user_id=reservation.user_id,
                    event_type=urgency_type,
                    title=title,
                    body=body,
                    data={"reservation_id": str(reservation.id)},
                    db=db,
                )

                ttl = max(int((flight.departure_at - now).total_seconds()), 3600)
                await redis.set(dedup_key, "1", ex=ttl)

                alerts_created += 1
                logger.info(
                    "departure_alert.created",
                    reservation_id=reservation.id,
                    urgency=urgency_type,
                    minutes_until_leave=round(minutes_until_leave),
                )
                break

        await db.commit()

    logger.info("check_departure_alerts.done", alerts_created=alerts_created)
    return alerts_created
