"""Finalize passenger details and ticket activation."""

from __future__ import annotations

from datetime import UTC, datetime

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.ticket_qr import qr_content_for_ticket, write_qr_png
from app.data.airlines import carrier_name
from app.models.booking_passengers import BookingPassenger
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import TicketStatus
from app.schemas.booking_passengers import PassengerDetailsSubmit
from app.schemas.reservations import ReservationDetailRead
from app.services.booking_utils import is_valid_seat, normalize_seat
from app.services.passenger_duplicate import (
    find_passenger_on_flight,
    normalize_passport_number,
    passenger_seat_on_match,
)


def activate_all_passenger_tickets(reservation: Reservation) -> None:
    """Generate per-passenger QR codes and mark the booking ticket valid."""
    if reservation.passenger_details_completed_at is None:
        return
    if reservation.status != ReservationStatus.PAID.value:
        return

    ticket = reservation.ticket
    flight = reservation.flight
    if ticket is None or flight is None:
        return

    passengers = sorted(reservation.passengers, key=lambda row: row.sequence)
    carrier = carrier_name(flight.carrier_code)
    if ticket.ordered_by_user_id is None:
        ticket.ordered_by_user_id = reservation.user_id

    for passenger in passengers:
        if passenger.ordered_by_user_id is None:
            passenger.ordered_by_user_id = reservation.user_id
        passenger_ticket_number = f"{ticket.ticket_number}-{passenger.sequence:02d}"
        passenger_display = f"{passenger.family_name}/{passenger.given_name}"
        seat = passenger.seat or reservation.seat

        qr_plain = qr_content_for_ticket(
            passenger_ticket_number,
            flight_id=flight.id,
            origin_iata=flight.origin_iata,
            destination_iata=flight.destination_iata,
            departure_at=flight.departure_at.isoformat(),
            carrier_code=flight.carrier_code,
            flight_number=flight.flight_number,
            seat=seat,
            pnr=reservation.pnr,
            passenger_name=passenger_display,
            carrier_name=carrier,
        )
        passenger.passenger_ticket_number = passenger_ticket_number
        passenger.qr_code = qr_plain
        safe_name = passenger_ticket_number.replace("-", "")
        passenger.qr_image_path = write_qr_png(qr_plain, f"{safe_name}.png")

    if passengers:
        primary = passengers[0]
        ticket.qr_code = primary.qr_code or ticket.qr_code
        ticket.qr_image_path = primary.qr_image_path or ticket.qr_image_path
    ticket.status = TicketStatus.VALID.value


def activate_ticket_after_passenger_details(
    reservation: Reservation,
    *,
    passenger_display: str | None = None,
) -> None:
    """Backward-compatible alias for payment webhook and legacy callers."""
    del passenger_display
    activate_all_passenger_tickets(reservation)


async def submit_passenger_details(
    db: AsyncSession,
    *,
    reservation_id: int,
    user_id: int,
    body: PassengerDetailsSubmit,
) -> ReservationDetailRead:
    result = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
            selectinload(Reservation.passengers),
            selectinload(Reservation.reservation_seats),
        )
        .where(Reservation.id == reservation_id),
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    if reservation.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your reservation")
    if reservation.status not in (
        ReservationStatus.BOOKED.value,
        ReservationStatus.PAID.value,
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passenger details cannot be submitted for this reservation",
        )
    if reservation.passenger_details_completed_at is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Passenger details already submitted",
        )
    if len(body.passengers) != reservation.adults_count:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Expected {reservation.adults_count} passenger(s)",
        )

    reserved_seats = {
        normalize_seat(row.seat)
        for row in sorted(reservation.reservation_seats, key=lambda r: r.sequence)
    }
    if not reserved_seats:
        reserved_seats = {normalize_seat(reservation.seat)}

    today = datetime.now(UTC).date()

    seen_passports: set[str] = set()
    seen_seats: set[str] = set()
    for p in body.passengers:
        passport = normalize_passport_number(p.passport_number)
        if passport in seen_passports:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Duplicate passport numbers in the same booking",
            )
        seen_passports.add(passport)

        seat = normalize_seat(p.seat)
        if not is_valid_seat(seat):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid seat format (use row 1-99 and letter A-F, e.g. 12A)",
            )
        if seat not in reserved_seats:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Seat is not part of this booking",
            )
        if seat in seen_seats:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Duplicate seat numbers in the same booking",
            )
        seen_seats.add(seat)

        existing = await find_passenger_on_flight(
            db,
            flight_id=reservation.flight_id,
            passport_number=passport,
            exclude_reservation_id=reservation.id,
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "passenger_already_on_flight",
                    "passport_number": passport,
                    "existing_seat": passenger_seat_on_match(existing),
                    "existing_reservation_id": existing.reservation.id,
                },
            )

    for idx, p in enumerate(body.passengers, start=1):
        if p.passport_expiry <= today:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Passport must be valid (expiry in the future)",
            )
        db.add(
            BookingPassenger(
                reservation_id=reservation.id,
                sequence=idx,
                ordered_by_user_id=reservation.user_id,
                title=p.title.upper(),
                given_name=p.given_name.strip().upper(),
                family_name=p.family_name.strip().upper(),
                date_of_birth=p.date_of_birth,
                gender=p.gender.upper(),
                nationality=p.nationality.upper(),
                passport_number=p.passport_number.strip().upper(),
                passport_expiry=p.passport_expiry,
                passport_issuing_country=p.passport_issuing_country.upper(),
                seat=normalize_seat(p.seat),
            ),
        )

    reservation.passenger_details_completed_at = datetime.now(UTC)
    await db.flush()

    if reservation.status == ReservationStatus.PAID.value:
        activate_all_passenger_tickets(reservation)

    await db.commit()

    result2 = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
            selectinload(Reservation.passengers),
            selectinload(Reservation.reservation_seats),
        )
        .where(Reservation.id == reservation_id),
    )
    return ReservationDetailRead.from_orm_reservation(result2.scalar_one())


async def get_reservation_detail(
    db: AsyncSession,
    *,
    reservation_id: int,
    user_id: int,
) -> ReservationDetailRead:
    result = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
            selectinload(Reservation.passengers),
            selectinload(Reservation.reservation_seats),
        )
        .where(Reservation.id == reservation_id),
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    if reservation.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your reservation")
    return ReservationDetailRead.from_orm_reservation(reservation)
