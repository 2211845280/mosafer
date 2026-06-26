"""Tests for departure reminder worker."""

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
from app.models.user_preferences import UserPreference
from app.models.users import User
from app.schemas.departure_plan import (
    DeparturePlanResult,
    TrafficLevel,
    TransportMode,
    WeatherCondition,
    WeatherResult,
)
from app.workers.departure_alert import check_departure_alerts


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


@pytest.mark.asyncio
async def test_departure_reminder_uses_new_event_types(
    prepare_schema,
    db_session: AsyncSession,
    authed_user: tuple[User, dict[str, str]],
    seeded_reservation,
    monkeypatch,
) -> None:
    user, _ = authed_user
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
    flight.departure_at = now + timedelta(hours=5)
    flight.arrival_at = flight.departure_at + timedelta(hours=3)

    pref = UserPreference(
        user_id=user.id,
        home_lat=30.0444,
        home_lng=31.2357,
        notification_enabled=True,
        preferred_transport="driving",
    )
    db_session.add(pref)

    leave_at = now + timedelta(minutes=25)
    monkeypatch.setattr(
        "app.services.trip_reminder_support._planner.calculate",
        AsyncMock(return_value=_fake_plan(leave_at, flight.departure_at)),
    )

    await db_session.commit()

    redis = _FakeRedis()
    created = await check_departure_alerts(_worker_ctx(db_session, redis))
    assert created == 1

    result = await db_session.execute(
        select(Notification).where(Notification.user_id == user.id),
    )
    note = result.scalars().first()
    assert note is not None
    assert note.type == "home_departure_30m"
    assert "Departure" in note.title or "المغادرة" in note.title
