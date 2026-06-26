"""Shared helpers for trip todo and departure reminder workers."""

from __future__ import annotations

from datetime import UTC, datetime
from enum import StrEnum

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.airports import Airport
from app.models.flights import Flight
from app.models.reservations import Reservation
from app.models.trip_todos import TripTodo
from app.models.user_preferences import UserPreference
from app.schemas.departure_plan import DeparturePlanResult, TransportMode
from app.services.departure_planner import DeparturePlanner
from app.services.notification_copy import TripTodoVariant

logger = structlog.get_logger(__name__)

_planner = DeparturePlanner()

_TRANSPORT_ALIASES: dict[str, str] = {
    "car": "driving",
    "drive": "driving",
    "driving": "driving",
    "transit": "transit",
    "walking": "walking",
    "taxi": "taxi",
}


class TodoReminderState(StrEnum):
    skip_complete = "skip_complete"
    empty = "empty"
    incomplete = "incomplete"


def resolve_transport_mode(pref: UserPreference | None) -> TransportMode:
    raw = (pref.preferred_transport if pref else "driving") or "driving"
    normalized = _TRANSPORT_ALIASES.get(raw.strip().lower(), raw.strip().lower())
    try:
        return TransportMode(normalized)
    except ValueError:
        return TransportMode.driving


def flight_label(flight: Flight) -> str:
    return f"{flight.carrier_code}{flight.flight_number}"


def user_locale(pref: UserPreference | None) -> str:
    if pref and pref.language:
        return pref.language
    return "en"


async def load_active_reservations(
    db: AsyncSession,
    *,
    now: datetime,
    window_end: datetime,
) -> list[Reservation]:
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
    return list(result.scalars().all())


async def load_user_preference(db: AsyncSession, user_id: int) -> UserPreference | None:
    result = await db.execute(
        select(UserPreference).where(UserPreference.user_id == user_id),
    )
    return result.scalar_one_or_none()


async def load_airport(db: AsyncSession, iata: str) -> Airport | None:
    result = await db.execute(select(Airport).where(Airport.iata_code == iata))
    return result.scalar_one_or_none()


async def build_departure_plan(
    db: AsyncSession,
    *,
    reservation: Reservation,
    pref: UserPreference,
) -> DeparturePlanResult | None:
    flight = reservation.flight
    airport = await load_airport(db, flight.origin_iata)
    if airport is None or airport.latitude is None or airport.longitude is None:
        return None

    dest_airport = await load_airport(db, flight.destination_iata)
    dest_country = dest_airport.country if dest_airport else "Unknown"
    transport = resolve_transport_mode(pref)

    try:
        return await _planner.calculate(
            user_lat=float(pref.home_lat),
            user_lng=float(pref.home_lng),
            airport_lat=float(airport.latitude),
            airport_lng=float(airport.longitude),
            airport_country=dest_country,
            origin_country=airport.country,
            departure_at=flight.departure_at,
            transport_mode=transport,
            destination_airport_lat=(
                float(dest_airport.latitude)
                if dest_airport and dest_airport.latitude
                else None
            ),
            destination_airport_lng=(
                float(dest_airport.longitude)
                if dest_airport and dest_airport.longitude
                else None
            ),
            arrival_at=flight.arrival_at,
        )
    except Exception:
        logger.exception(
            "trip_reminder.plan_failed",
            reservation_id=reservation.id,
        )
        return None


async def todo_reminder_state(
    db: AsyncSession,
    reservation_id: int,
) -> TodoReminderState:
    counts = await db.execute(
        select(
            func.count(TripTodo.id),
            func.count(TripTodo.id).filter(TripTodo.is_completed.is_(False)),
        ).where(TripTodo.reservation_id == reservation_id),
    )
    total, incomplete = counts.one()
    if total == 0:
        return TodoReminderState.empty
    if incomplete == 0:
        return TodoReminderState.skip_complete
    return TodoReminderState.incomplete


def todo_variant(state: TodoReminderState) -> TripTodoVariant | None:
    if state == TodoReminderState.empty:
        return "empty"
    if state == TodoReminderState.incomplete:
        return "incomplete"
    return None


def minutes_until(target: datetime, now: datetime) -> float:
    if target.tzinfo is None:
        target = target.replace(tzinfo=UTC)
    if now.tzinfo is None:
        now = now.replace(tzinfo=UTC)
    return (target - now).total_seconds() / 60


async def dedup_already_sent(redis, key: str) -> bool:
    return bool(await redis.get(key))


async def mark_dedup_sent(redis, key: str, ttl_seconds: int) -> None:
    await redis.set(key, "1", ex=max(ttl_seconds, 3600))
