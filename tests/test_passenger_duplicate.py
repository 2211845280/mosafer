"""Tests for duplicate passenger detection on a flight."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.security import hash_password
from app.models.booking_passengers import BookingPassenger
from app.models.flights import Flight
from app.models.reservations import Reservation, ReservationStatus
from app.models.reservation_seats import ReservationSeat
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.booking_passengers import BookingPassengerCreate, PassengerDetailsSubmit
from app.services.passenger_duplicate import find_passenger_on_flight, list_blocked_passports_on_flight
from app.services.passenger_details_service import submit_passenger_details


def _passenger_body(*, passport_number: str = "AB1234567", seat: str = "12A") -> PassengerDetailsSubmit:
    return PassengerDetailsSubmit(
        passengers=[
            BookingPassengerCreate(
                title="MR",
                given_name="JOHN",
                family_name="DOE",
                date_of_birth=date(1990, 1, 1),
                gender="M",
                nationality="LBY",
                passport_number=passport_number,
                passport_expiry=date(2030, 1, 1),
                passport_issuing_country="LBY",
                seat=seat,
            ),
        ],
    )


@pytest.mark.asyncio
async def test_find_passenger_on_flight_returns_match(prepare_schema, db_session: AsyncSession):
    user = User(email="dup@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-dup-1",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="100",
        departure_at=datetime(2026, 7, 1, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 7, 1, 12, 0, tzinfo=UTC),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="12A",
        status=ReservationStatus.PAID.value,
        passenger_details_completed_at=datetime.now(UTC),
    )
    db_session.add(reservation)
    await db_session.flush()
    db_session.add(
        BookingPassenger(
            reservation_id=reservation.id,
            sequence=1,
            title="MR",
            given_name="JOHN",
            family_name="DOE",
            date_of_birth=date(1990, 1, 1),
            gender="M",
            nationality="LBY",
            passport_number="AB1234567",
            passport_expiry=date(2030, 1, 1),
            passport_issuing_country="LBY",
        ),
    )
    await db_session.commit()

    match = await find_passenger_on_flight(
        db_session,
        flight_id=flight.id,
        passport_number="ab1234567",
        exclude_reservation_id=None,
    )
    assert match is not None
    assert match.reservation.seat == "12A"


@pytest.mark.asyncio
async def test_canceled_reservation_not_counted(prepare_schema, db_session: AsyncSession):
    user = User(email="canceled@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-dup-2",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="101",
        departure_at=datetime(2026, 7, 2, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 7, 2, 12, 0, tzinfo=UTC),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="14B",
        status=ReservationStatus.CANCELED.value,
        passenger_details_completed_at=datetime.now(UTC),
    )
    db_session.add(reservation)
    await db_session.flush()
    db_session.add(
        BookingPassenger(
            reservation_id=reservation.id,
            sequence=1,
            title="MR",
            given_name="JANE",
            family_name="DOE",
            date_of_birth=date(1992, 2, 2),
            gender="F",
            nationality="LBY",
            passport_number="CD7654321",
            passport_expiry=date(2031, 1, 1),
            passport_issuing_country="LBY",
        ),
    )
    await db_session.commit()

    match = await find_passenger_on_flight(
        db_session,
        flight_id=flight.id,
        passport_number="CD7654321",
        exclude_reservation_id=None,
    )
    assert match is None


@pytest.mark.asyncio
async def test_submit_passenger_details_rejects_duplicate_passport(
    prepare_schema,
    db_session: AsyncSession,
):
    user = User(email="submit-dup@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-dup-3",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="102",
        departure_at=datetime(2026, 7, 3, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 7, 3, 12, 0, tzinfo=UTC),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    first = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="1A",
        status=ReservationStatus.PAID.value,
        passenger_details_completed_at=datetime.now(UTC),
    )
    second = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="2B",
        status=ReservationStatus.PAID.value,
    )
    db_session.add_all([first, second])
    await db_session.flush()

    db_session.add(
        BookingPassenger(
            reservation_id=first.id,
            sequence=1,
            title="MR",
            given_name="ALI",
            family_name="AHMED",
            date_of_birth=date(1988, 3, 3),
            gender="M",
            nationality="LBY",
            passport_number="XY9988776",
            passport_expiry=date(2032, 1, 1),
            passport_issuing_country="LBY",
        ),
    )
    db_session.add(
        Ticket(
            booking_id=second.id,
            ticket_number="TNTEST0001",
            qr_code="{}",
            status=TicketStatus.PENDING_PASSENGER.value,
        ),
    )
    await db_session.commit()

    with pytest.raises(HTTPException) as exc_info:
        await submit_passenger_details(
            db_session,
            reservation_id=second.id,
            user_id=user.id,
            body=_passenger_body(passport_number="XY9988776", seat="2B"),
        )

    assert exc_info.value.status_code == 409
    detail = exc_info.value.detail
    assert isinstance(detail, dict)
    assert detail["code"] == "passenger_already_on_flight"
    assert detail["existing_seat"] == "1A"


@pytest.mark.asyncio
async def test_list_blocked_passports_on_flight(prepare_schema, db_session: AsyncSession):
    user = User(email="blocked@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-dup-4",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="103",
        departure_at=datetime.now(UTC) + timedelta(days=5),
        arrival_at=datetime.now(UTC) + timedelta(days=5, hours=4),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="3C",
        status=ReservationStatus.PAID.value,
        passenger_details_completed_at=datetime.now(UTC),
    )
    db_session.add(reservation)
    await db_session.flush()
    db_session.add(
        BookingPassenger(
            reservation_id=reservation.id,
            sequence=1,
            title="MS",
            given_name="SARA",
            family_name="ALI",
            date_of_birth=date(1995, 4, 4),
            gender="F",
            nationality="LBY",
            passport_number="PP1122334",
            passport_expiry=date(2033, 1, 1),
            passport_issuing_country="LBY",
        ),
    )
    await db_session.commit()

    blocked = await list_blocked_passports_on_flight(db_session, flight_id=flight.id)
    assert blocked == ["PP1122334"]


@pytest.mark.asyncio
async def test_submit_passenger_details_on_booked_does_not_activate_ticket(
    prepare_schema,
    db_session: AsyncSession,
) -> None:
    """Passenger details can be saved while status is booked; ticket stays pending."""
    user = User(email="booked@example.com", password_hash=hash_password("secret"))
    db_session.add(user)
    await db_session.flush()

    flight = Flight(
        provider_flight_id="mock-booked-1",
        origin_iata="CAI",
        destination_iata="DXB",
        carrier_code="MS",
        flight_number="200",
        departure_at=datetime(2026, 8, 1, 8, 0, tzinfo=UTC),
        arrival_at=datetime(2026, 8, 1, 12, 0, tzinfo=UTC),
        total_seats=180,
    )
    db_session.add(flight)
    await db_session.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat="12A",
        status=ReservationStatus.BOOKED.value,
        pnr="BOOKED01",
        cabin_class="economy",
        adults_count=1,
    )
    db_session.add(reservation)
    await db_session.flush()
    db_session.add(ReservationSeat(
        reservation_id=reservation.id,
        flight_id=flight.id,
        seat="12A",
        sequence=1,
    ))
    db_session.add(
        Ticket(
            booking_id=reservation.id,
            ticket_number="TK-BOOKED",
            qr_code="{}",
            status=TicketStatus.PENDING_PASSENGER.value,
        )
    )
    await db_session.commit()

    result = await submit_passenger_details(
        db_session,
        reservation_id=reservation.id,
        user_id=user.id,
        body=_passenger_body(),
    )
    assert result.passenger_details_completed_at is not None

    await db_session.refresh(reservation)
    ticket_result = await db_session.execute(
        select(Ticket).where(Ticket.booking_id == reservation.id)
    )
    ticket = ticket_result.scalar_one()
    assert reservation.status == ReservationStatus.BOOKED.value
    assert ticket.status == TicketStatus.PENDING_PASSENGER.value
    assert ticket.qr_code == "{}"
