"""Tests for per-passenger ticket QR generation."""

from __future__ import annotations

from datetime import UTC, date, datetime

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.booking_passengers import BookingPassenger
from app.models.flights import Flight
from app.models.reservation_seats import ReservationSeat
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.booking_passengers import BookingPassengerCreate, PassengerDetailsSubmit
from app.services.passenger_details_service import (
    activate_all_passenger_tickets,
    submit_passenger_details,
)


def _passenger(
    *,
    passport_number: str,
    seat: str,
    given_name: str = "JOHN",
    family_name: str = "DOE",
) -> BookingPassengerCreate:
    return BookingPassengerCreate(
        title="MR",
        given_name=given_name,
        family_name=family_name,
        date_of_birth=date(1990, 1, 1),
        gender="M",
        nationality="LBY",
        passport_number=passport_number,
        passport_expiry=date(2033, 1, 1),
        passport_issuing_country="LBY",
        seat=seat,
    )


@pytest.mark.asyncio
async def test_submit_two_passengers_on_booked(prepare_schema, db_session: AsyncSession) -> None:
    user = User(email="multi@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-multi-1#2026-09-01",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="300",
        departure_at=datetime(2026, 9, 1, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 9, 1, 12, 0, tzinfo=UTC),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="12A",
        status=ReservationStatus.BOOKED.value,
        adults_count=2,
    )
    db_session.add(reservation)
    await db_session.flush()
    db_session.add_all(
        [
            ReservationSeat(
                reservation_id=reservation.id,
                flight_id=flight.id,
                seat="12A",
                sequence=1,
            ),
            ReservationSeat(
                reservation_id=reservation.id,
                flight_id=flight.id,
                seat="12B",
                sequence=2,
            ),
        ],
    )
    db_session.add(
        Ticket(
            booking_id=reservation.id,
            ticket_number="TK-MULTI01",
            qr_code="{}",
            status=TicketStatus.PENDING_PASSENGER.value,
        ),
    )
    await db_session.commit()

    result = await submit_passenger_details(
        db_session,
        reservation_id=reservation.id,
        user_id=user.id,
        body=PassengerDetailsSubmit(
            passengers=[
                _passenger(passport_number="PP1111111", seat="12A", given_name="ALI"),
                _passenger(passport_number="PP2222222", seat="12B", given_name="SARA"),
            ],
        ),
    )
    assert result.passenger_details_completed_at is not None
    assert len(result.passengers) == 2


@pytest.mark.asyncio
async def test_activate_all_passenger_tickets_generates_per_passenger_qr(
    prepare_schema,
    db_session: AsyncSession,
) -> None:
    user = User(email="qr@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-multi-2#2026-09-02",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="301",
        departure_at=datetime(2026, 9, 2, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 9, 2, 12, 0, tzinfo=UTC),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="5A",
        status=ReservationStatus.PAID.value,
        pnr="ABC123",
        adults_count=2,
        passenger_details_completed_at=datetime.now(UTC),
    )
    db_session.add(reservation)
    await db_session.flush()

    db_session.add_all(
        [
            BookingPassenger(
                reservation_id=reservation.id,
                sequence=1,
                title="MR",
                given_name="ALI",
                family_name="AHMED",
                date_of_birth=date(1990, 1, 1),
                gender="M",
                nationality="LBY",
                passport_number="PP3333333",
                passport_expiry=date(2033, 1, 1),
                passport_issuing_country="LBY",
                seat="5A",
            ),
            BookingPassenger(
                reservation_id=reservation.id,
                sequence=2,
                title="MS",
                given_name="SARA",
                family_name="AHMED",
                date_of_birth=date(1992, 2, 2),
                gender="F",
                nationality="LBY",
                passport_number="PP4444444",
                passport_expiry=date(2033, 1, 1),
                passport_issuing_country="LBY",
                seat="5B",
            ),
        ],
    )
    db_session.add(
        Ticket(
            booking_id=reservation.id,
            ticket_number="TK-QRTEST",
            qr_code="{}",
            status=TicketStatus.PENDING_PASSENGER.value,
        ),
    )
    await db_session.commit()

    loaded = await db_session.get(Reservation, reservation.id)
    assert loaded is not None
    ticket_result = await db_session.execute(
        select(Ticket).where(Ticket.booking_id == reservation.id),
    )
    ticket = ticket_result.scalar_one()
    loaded.ticket = ticket

    flight_row = await db_session.get(Flight, flight.id)
    loaded.flight = flight_row

    pax_result = await db_session.execute(
        select(BookingPassenger).where(BookingPassenger.reservation_id == reservation.id),
    )
    loaded.passengers = list(pax_result.scalars().all())

    activate_all_passenger_tickets(loaded)
    await db_session.commit()

    passengers = sorted(loaded.passengers, key=lambda p: p.sequence)
    assert passengers[0].passenger_ticket_number == "TK-QRTEST-01"
    assert passengers[1].passenger_ticket_number == "TK-QRTEST-02"
    assert passengers[0].qr_code is not None
    assert passengers[1].qr_code is not None
    assert passengers[0].qr_code != passengers[1].qr_code
    assert "5A" in passengers[0].qr_code
    assert "5B" in passengers[1].qr_code
    assert ticket.status == TicketStatus.VALID.value
    assert ticket.qr_code == passengers[0].qr_code
