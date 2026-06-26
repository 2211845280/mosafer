"""ARQ cron task that reminds users to complete trip todos before departure."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import structlog

from app.services.notification_copy import trip_todo_reminder_copy
from app.services.notification_dispatcher import NotificationDispatcher
from app.services.trip_reminder_support import (
    TodoReminderState,
    build_departure_plan,
    dedup_already_sent,
    flight_label,
    load_active_reservations,
    load_user_preference,
    mark_dedup_sent,
    minutes_until,
    todo_reminder_state,
    todo_variant,
    user_locale,
)

logger = structlog.get_logger(__name__)

_dispatcher = NotificationDispatcher()

# (event_type, threshold_minutes, reference: "flight" | "leave")
_TODO_THRESHOLDS: list[tuple[str, int, str]] = [
    ("trip_todo_14d", 14 * 24 * 60, "flight"),
    ("trip_todo_7d", 7 * 24 * 60, "flight"),
    ("trip_todo_3d", 3 * 24 * 60, "flight"),
    ("trip_todo_1d", 24 * 60, "flight"),
    ("trip_todo_6h", 6 * 60, "leave"),
    ("trip_todo_3h", 3 * 60, "leave"),
]


async def check_trip_todo_reminders(ctx: dict) -> int:
    """Send trip todo reminders when tasks are empty or incomplete.

    Returns the number of reminders created.
    """
    db_factory = ctx.get("db")
    redis = ctx.get("redis")
    if db_factory is None or redis is None:
        logger.error("check_trip_todo_reminders.missing_context")
        return 0

    now = datetime.now(UTC)
    window_end = now + timedelta(days=15)
    reminders_created = 0

    async with db_factory() as db:
        reservations = await load_active_reservations(db, now=now, window_end=window_end)

        for reservation in reservations:
            flight = reservation.flight
            pref = await load_user_preference(db, reservation.user_id)

            if pref is None or pref.notification_enabled is False:
                continue

            todo_state = await todo_reminder_state(db, reservation.id)
            if todo_state == TodoReminderState.skip_complete:
                continue

            variant = todo_variant(todo_state)
            if variant is None:
                continue

            plan = None
            if pref.home_lat is not None and pref.home_lng is not None:
                plan = await build_departure_plan(db, reservation=reservation, pref=pref)

            label = flight_label(flight)
            locale = user_locale(pref)

            for event_type, threshold_min, reference in _TODO_THRESHOLDS:
                if reference == "leave":
                    if plan is None:
                        continue
                    remaining = minutes_until(plan.leave_at, now)
                else:
                    remaining = minutes_until(flight.departure_at, now)

                if remaining > threshold_min:
                    continue

                dedup_key = f"trip_todo_alert:{reservation.id}:{event_type}"
                if await dedup_already_sent(redis, dedup_key):
                    continue

                title, body = trip_todo_reminder_copy(
                    locale,
                    variant=variant,
                    flight_label=label,
                )

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

                reminders_created += 1
                logger.info(
                    "trip_todo_reminder.created",
                    reservation_id=reservation.id,
                    event_type=event_type,
                    variant=variant,
                    minutes_remaining=round(remaining),
                )

        await db.commit()

    logger.info("check_trip_todo_reminders.done", reminders_created=reminders_created)
    return reminders_created
