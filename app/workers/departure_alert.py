"""ARQ cron task that sends departure-time reminders (flight and home leave)."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import structlog

from app.services.notification_copy import departure_schedule_copy
from app.services.notification_dispatcher import NotificationDispatcher
from app.services.trip_reminder_support import (
    build_departure_plan,
    dedup_already_sent,
    flight_label,
    load_active_reservations,
    load_user_preference,
    mark_dedup_sent,
    minutes_until,
    user_locale,
)

logger = structlog.get_logger(__name__)

_dispatcher = NotificationDispatcher()

# Highest urgency first — only one alert per reservation per cron run.
# (event_type, threshold_minutes, reference: "flight" | "leave")
_DEPARTURE_REMINDERS: list[tuple[str, int, str]] = [
    ("home_departure_critical", 15, "leave"),
    ("home_departure_30m", 30, "leave"),
    ("home_departure_2h", 120, "leave"),
    ("flight_departure_6h", 360, "flight"),
]


async def check_departure_alerts(ctx: dict) -> int:
    """Check upcoming flights and send departure reminders.

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
        reservations = await load_active_reservations(db, now=now, window_end=window_end)

        for reservation in reservations:
            flight = reservation.flight
            pref = await load_user_preference(db, reservation.user_id)

            if pref is None or pref.notification_enabled is False:
                continue

            plan = None
            if pref.home_lat is not None and pref.home_lng is not None:
                plan = await build_departure_plan(db, reservation=reservation, pref=pref)

            label = flight_label(flight)
            locale = user_locale(pref)

            for event_type, threshold_min, reference in _DEPARTURE_REMINDERS:
                if reference == "leave":
                    if plan is None:
                        continue
                    remaining = minutes_until(plan.leave_at, now)
                else:
                    remaining = minutes_until(flight.departure_at, now)

                if remaining > threshold_min:
                    continue

                dedup_key = f"departure_alert:{reservation.id}:{event_type}"
                if await dedup_already_sent(redis, dedup_key):
                    continue

                title, body = departure_schedule_copy(locale, event_type, label)

                await _dispatcher.dispatch(
                    user_id=reservation.user_id,
                    event_type=event_type,
                    title=title,
                    body=body,
                    data={"reservation_id": str(reservation.id)},
                    db=db,
                )

                ttl = max(int(minutes_until(flight.departure_at, now) * 60), 3600)
                await mark_dedup_sent(redis, dedup_key, ttl)

                alerts_created += 1
                logger.info(
                    "departure_alert.created",
                    reservation_id=reservation.id,
                    event_type=event_type,
                    minutes_remaining=round(remaining),
                )
                break

        await db.commit()

    logger.info("check_departure_alerts.done", alerts_created=alerts_created)
    return alerts_created
