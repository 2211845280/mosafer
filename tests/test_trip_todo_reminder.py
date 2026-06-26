"""Tests for trip todo reminder worker."""

from __future__ import annotations

from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.airports import Airport
from app.models.flights import Flight
from app.models.notifications import Notification
from app.models.reservations import Reservation
from app.models.trip_todos import TripTodo
from app.models.user_preferences import UserPreference
from app.models.users import User
from app.schemas.departure_plan import (
    DeparturePlanResult,
    TrafficLevel,
    TransportMode,
    WeatherCondition,
    WeatherResult,
)
from app.workers.trip_todo_reminder import check_trip_todo_reminders


class _FakeRedis:
    def __init__(self) -> None:
        self._store: dict[str, str] = {}

    async def get(self, key: str) -> str | None:
        return self._store.get(key)

    async def set(self, key: str, value: str, ex: int | None = None) -> None:
        self._store[key] = value


def _fake_plan(leave_at: datetime, departure_at: datetime | None = None) -> DeparturePlanResult:
    dep = departure_at or leave_at + timedelta(hours=3)
    weather = WeatherResult(
        condition=WeatherCondition.clear,
        temperature_c=25.0,
        visibility_km=10.0,
        description="Clear",
    )
    return DeparturePlanResult(
        leave_at=leave_at,
        travel_minutes=60,
        distance_km=30.0,
        check_in_buffer_minutes=120,
        weather_buffer_minutes=15,
        weather=weather,
        transport_mode=TransportMode.driving,
        traffic_level=TrafficLevel.low,
        flight_departure_at=dep,
    )


def _worker_ctx(db_session: AsyncSession, redis: _FakeRedis) -> dict:
    @asynccontextmanager
    async def db_factory():
        yield db_session

    return {"db": db_factory, "redis": redis}


async def _setup_trip(
    db_session: AsyncSession,
    user: User,
    *,
    departure_in: timedelta,
    todos: list[tuple[str, bool]],
) -> int:
    origin = (
        await db_session.execute(select(Airport).where(Airport.iata_code == "CAI"))
    ).scalar_one()
    origin.latitude = 30.1219
    origin.longitude = 31.4056
    dest = (
        await db_session.execute(select(Airport).where(Airport.iata_code == "DXB"))
    ).scalar_one()
    dest.latitude = 25.2532
    dest.longitude = 55.3657

    flight = (
        await db_session.execute(select(Flight).where(Flight.origin_iata == "CAI"))
    ).scalar_one()
    now = datetime.now(UTC)
    flight.departure_at = now + departure_in
    flight.arrival_at = flight.departure_at + timedelta(hours=3)

    reservation = (
        await db_session.execute(
            select(Reservation).where(Reservation.user_id == user.id),
        )
    ).scalar_one()

    pref = (
        await db_session.execute(
            select(UserPreference).where(UserPreference.user_id == user.id),
        )
    ).scalar_one_or_none()
    if pref is None:
        pref = UserPreference(user_id=user.id)
        db_session.add(pref)
    pref.home_lat = 30.0444
    pref.home_lng = 31.2357
    pref.notification_enabled = True
    pref.preferred_transport = "driving"

    await db_session.execute(
        select(TripTodo).where(TripTodo.reservation_id == reservation.id),
    )
    for title, completed in todos:
        db_session.add(
            TripTodo(
                reservation_id=reservation.id,
                user_id=user.id,
                title=title,
                is_completed=completed,
            ),
        )

    await db_session.commit()
    return reservation.id


@pytest.mark.asyncio
async def test_trip_todo_skips_when_all_complete(
    prepare_schema,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
    seeded_reservation,
    monkeypatch,
) -> None:
    user, _ = authed_user
    await _setup_trip(
        db_session,
        user,
        departure_in=timedelta(days=2),
        todos=[("Pack", True), ("Documents", True)],
    )

    monkeypatch.setattr(
        "app.services.trip_reminder_support._planner.calculate",
        AsyncMock(
            return_value=_fake_plan(datetime.now(UTC) + timedelta(hours=5)),
        ),
    )

    redis = _FakeRedis()
    created = await check_trip_todo_reminders(_worker_ctx(db_session, redis))
    assert created == 0


@pytest.mark.asyncio
async def test_trip_todo_empty_list_sends_fill_reminder(
    prepare_schema,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
    seeded_reservation,
    monkeypatch,
) -> None:
    user, _ = authed_user
    await _setup_trip(db_session, user, departure_in=timedelta(days=2), todos=[])

    monkeypatch.setattr(
        "app.services.trip_reminder_support._planner.calculate",
        AsyncMock(
            return_value=_fake_plan(datetime.now(UTC) + timedelta(hours=5)),
        ),
    )

    redis = _FakeRedis()
    created = await check_trip_todo_reminders(_worker_ctx(db_session, redis))
    assert created >= 1

    result = await db_session.execute(
        select(Notification).where(Notification.user_id == user.id),
    )
    notes = result.scalars().all()
    assert any(n.type.startswith("trip_todo_") for n in notes)
    assert any("fill" in n.body.lower() or "تعبئة" in n.body for n in notes)


@pytest.mark.asyncio
async def test_trip_todo_incomplete_sends_complete_reminder(
    prepare_schema,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
    seeded_reservation,
    monkeypatch,
) -> None:
    user, _ = authed_user
    await _setup_trip(
        db_session,
        user,
        departure_in=timedelta(days=2),
        todos=[("Pack", False)],
    )

    monkeypatch.setattr(
        "app.services.trip_reminder_support._planner.calculate",
        AsyncMock(
            return_value=_fake_plan(datetime.now(UTC) + timedelta(hours=5)),
        ),
    )

    redis = _FakeRedis()
    created = await check_trip_todo_reminders(_worker_ctx(db_session, redis))
    assert created >= 1

    result = await db_session.execute(
        select(Notification).where(Notification.user_id == user.id),
    )
    notes = result.scalars().all()
    assert any(
        "complete" in n.body.lower() or "إكمال" in n.body for n in notes
    )
