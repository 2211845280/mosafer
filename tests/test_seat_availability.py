"""Unit tests for seat availability service."""

from __future__ import annotations

from datetime import UTC, datetime

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.flights import Flight
from app.models.reservations import Reservation, ReservationStatus
from app.models.users import User
from app.services.seat_availability import (
    generate_all_seats,
    get_seat_availability,
    seat_rows_for_flight,
)
from app.core.security import hash_password


def test_seat_rows_for_flight_defaults():
    assert seat_rows_for_flight(None) == 30
    assert seat_rows_for_flight(120) == 20


def test_generate_all_seats():
    seats = generate_all_seats(2)
    assert seats == ["1A", "1B", "1C", "1D", "1E", "1F", "2A", "2B", "2C", "2D", "2E", "2F"]


@pytest.mark.asyncio
async def test_get_seat_availability_without_flight(prepare_schema, db_session: AsyncSession):
    availability = await get_seat_availability(
        db_session,
        provider_flight_id="mock-ist-lhr-1",
        departure_at=datetime(2026, 6, 10, 8, 0, tzinfo=UTC),
    )
    assert availability.rows == 30
    assert len(availability.available_seats) == 180
    assert availability.taken_seats == []


@pytest.mark.asyncio
async def test_get_seat_availability_excludes_taken_and_canceled(
    prepare_schema,
    db_session: AsyncSession,
):
    user = User(email="seat-test@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-ist-lhr-1#2026-06-10",
        origin_iata="IST",
        destination_iata="LHR",
        carrier_code="TK",
        flight_number="1980",
        departure_at=datetime(2026, 6, 10, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 6, 10, 12, 0, tzinfo=UTC),
        total_seats=12,
    )
    db_session.add(flight)
    await db_session.flush()

    db_session.add(
        Reservation(
            user_id=user.id,
            flight_id=flight.id,
            seat="1A",
            status=ReservationStatus.BOOKED.value,
        ),
    )
    db_session.add(
        Reservation(
            user_id=user.id,
            flight_id=flight.id,
            seat="2B",
            status=ReservationStatus.CANCELED.value,
        ),
    )
    await db_session.commit()

    availability = await get_seat_availability(
        db_session,
        provider_flight_id="mock-ist-lhr-1",
        departure_at=datetime(2026, 6, 10, 8, 0, tzinfo=UTC),
    )
    assert availability.rows == 2
    assert "1A" not in availability.available_seats
    assert "1A" in availability.taken_seats
    assert "2B" in availability.available_seats
