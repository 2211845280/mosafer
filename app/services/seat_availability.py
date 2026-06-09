"""Compute available seats for a flight."""

from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.flights import Flight
from app.services.checkout_session_service import collect_taken_seats_on_flight
from app.services.flight_identity import dated_provider_flight_id

SEAT_COLUMNS = ["A", "B", "C", "D", "E", "F"]
DEFAULT_ROWS = 30


@dataclass(frozen=True)
class SeatAvailability:
    provider_flight_id: str
    rows: int
    columns: list[str]
    available_seats: list[str]
    taken_seats: list[str]


def seat_rows_for_flight(total_seats: int | None) -> int:
    if total_seats is not None and total_seats > 0:
        return max(1, math.ceil(total_seats / len(SEAT_COLUMNS)))
    return DEFAULT_ROWS


def generate_all_seats(rows: int) -> list[str]:
    seats: list[str] = []
    for row in range(1, rows + 1):
        for col in SEAT_COLUMNS:
            seats.append(f"{row}{col}")
    return seats


async def get_seat_availability(
    db: AsyncSession,
    *,
    provider_flight_id: str,
    departure_at: datetime,
) -> SeatAvailability:
    """Return available and taken seats for a flight offer."""
    dated_id = dated_provider_flight_id(provider_flight_id, departure_at)
    legacy_id = provider_flight_id.strip()

    flight: Flight | None = None
    result = await db.execute(select(Flight).where(Flight.provider_flight_id == dated_id))
    flight = result.scalar_one_or_none()
    if flight is None and legacy_id != dated_id:
        legacy_result = await db.execute(
            select(Flight).where(Flight.provider_flight_id == legacy_id),
        )
        flight = legacy_result.scalar_one_or_none()

    rows = seat_rows_for_flight(flight.total_seats if flight else None)
    all_seats = generate_all_seats(rows)

    taken: set[str] = set()
    if flight is not None:
        taken = await collect_taken_seats_on_flight(db, flight_id=flight.id)

    available = [seat for seat in all_seats if seat not in taken]
    taken_sorted = sorted(seat for seat in all_seats if seat in taken)

    return SeatAvailability(
        provider_flight_id=dated_id,
        rows=rows,
        columns=list(SEAT_COLUMNS),
        available_seats=available,
        taken_seats=taken_sorted,
    )
