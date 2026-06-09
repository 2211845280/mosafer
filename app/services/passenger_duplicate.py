"""Detect duplicate passenger (passport) bookings on a flight."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.booking_passengers import BookingPassenger
from app.models.reservations import Reservation, ReservationStatus


def normalize_passport_number(passport_number: str) -> str:
    return passport_number.strip().upper()


def _active_reservation_passport_filter():
    """Paid bookings, or booked bookings with passenger details already saved."""
    return or_(
        Reservation.status == ReservationStatus.PAID.value,
        and_(
            Reservation.status == ReservationStatus.BOOKED.value,
            Reservation.passenger_details_completed_at.is_not(None),
        ),
    )


@dataclass(frozen=True)
class PassengerOnFlightMatch:
    booking_passenger: BookingPassenger
    reservation: Reservation


async def find_passenger_on_flight(
    db: AsyncSession,
    *,
    flight_id: int,
    passport_number: str,
    exclude_reservation_id: int | None = None,
) -> PassengerOnFlightMatch | None:
    """Return an active booking for this passport on the flight, if any."""
    normalized = normalize_passport_number(passport_number)
    if not normalized:
        return None

    query = (
        select(BookingPassenger)
        .join(Reservation, BookingPassenger.reservation_id == Reservation.id)
        .options(selectinload(BookingPassenger.reservation))
        .where(
            Reservation.flight_id == flight_id,
            Reservation.passenger_details_completed_at.is_not(None),
            _active_reservation_passport_filter(),
            BookingPassenger.passport_number == normalized,
        )
    )
    if exclude_reservation_id is not None:
        query = query.where(Reservation.id != exclude_reservation_id)

    result = await db.execute(query)
    passenger = result.scalar_one_or_none()
    if passenger is None:
        return None
    return PassengerOnFlightMatch(
        booking_passenger=passenger,
        reservation=passenger.reservation,
    )


def passenger_seat_on_match(match: PassengerOnFlightMatch) -> str:
    """Seat for duplicate-passenger error messages (per-passenger when available)."""
    if match.booking_passenger.seat:
        return match.booking_passenger.seat
    return match.reservation.seat


async def list_blocked_passports_on_flight(
    db: AsyncSession,
    *,
    flight_id: int,
) -> list[str]:
    """Passport numbers already used on a flight (details completed)."""
    result = await db.execute(
        select(BookingPassenger.passport_number)
        .join(Reservation, BookingPassenger.reservation_id == Reservation.id)
        .where(
            Reservation.flight_id == flight_id,
            Reservation.passenger_details_completed_at.is_not(None),
            _active_reservation_passport_filter(),
        )
        .distinct(),
    )
    return sorted({normalize_passport_number(p) for p in result.scalars().all() if p})
