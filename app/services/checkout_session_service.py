"""Checkout session lifecycle: seat hold, passenger capture, reservation materialization."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.ticket_qr import qr_content_for_ticket, write_qr_png
from app.data.airlines import carrier_name
from app.models.booking_passengers import BookingPassenger
from app.models.checkout_sessions import CheckoutSession, CheckoutSessionStatus
from app.models.payments import Payment
from app.models.reservation_seats import ReservationSeat
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.schemas.booking_passengers import PassengerDetailsSubmit
from app.schemas.checkout_sessions import CheckoutSessionDetailRead
from app.schemas.reservations import ReservationCreate
from app.services.booking_reference import generate_eticket_number, generate_pnr
from app.services.booking_utils import is_valid_seat, normalize_seat
from app.services.flight_identity import resolve_flight_for_booking
from app.services.passenger_details_service import activate_all_passenger_tickets
from app.services.passenger_duplicate import (
    find_passenger_on_flight,
    normalize_passport_number,
    passenger_seat_on_match,
)

CHECKOUT_TTL_MINUTES = 30


def _session_is_active(session: CheckoutSession, *, now: datetime | None = None) -> bool:
    current = now or datetime.now(UTC)
    return (
        session.status == CheckoutSessionStatus.OPEN.value
        and session.expires_at > current
    )


async def _load_owned_session(
    db: AsyncSession,
    *,
    session_id: int,
    user_id: int,
) -> CheckoutSession:
    result = await db.execute(
        select(CheckoutSession)
        .options(selectinload(CheckoutSession.flight))
        .where(CheckoutSession.id == session_id),
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Checkout session not found")
    if session.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your checkout session")
    return session


async def collect_taken_seats_on_flight(
    db: AsyncSession,
    *,
    flight_id: int,
    exclude_session_id: int | None = None,
) -> set[str]:
    from app.models.reservations import ReservationStatus as RS

    taken: set[str] = set()
    now = datetime.now(UTC)

    seat_rows = await db.execute(
        select(ReservationSeat.seat)
        .join(Reservation, ReservationSeat.reservation_id == Reservation.id)
        .where(
            ReservationSeat.flight_id == flight_id,
            Reservation.status != RS.CANCELED.value,
        ),
    )
    taken.update(normalize_seat(seat) for seat in seat_rows.scalars().all())

    legacy_rows = await db.execute(
        select(Reservation.seat).where(
            Reservation.flight_id == flight_id,
            Reservation.status != RS.CANCELED.value,
            Reservation.seat.is_not(None),
            Reservation.seat != "",
        ),
    )
    taken.update(normalize_seat(seat) for seat in legacy_rows.scalars().all() if seat)

    session_rows = await db.execute(
        select(CheckoutSession).where(
            CheckoutSession.flight_id == flight_id,
            CheckoutSession.status == CheckoutSessionStatus.OPEN.value,
            CheckoutSession.expires_at > now,
        ),
    )
    for session in session_rows.scalars().all():
        if exclude_session_id is not None and session.id == exclude_session_id:
            continue
        for seat in session.seats or []:
            taken.add(normalize_seat(seat))

    return taken


async def create_checkout_session(
    db: AsyncSession,
    *,
    user_id: int,
    data: ReservationCreate,
) -> CheckoutSessionDetailRead:
    normalized_seats: list[str] = []
    for raw in data.seats or []:
        seat = normalize_seat(raw)
        if not is_valid_seat(seat):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid seat format (use row 1-99 and letter A-F, e.g. 12A)",
            )
        normalized_seats.append(seat)

    if len(set(normalized_seats)) != len(normalized_seats):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duplicate seat numbers in the same booking",
        )

    flight = await resolve_flight_for_booking(
        db,
        provider_flight_id=data.provider_flight_id,
        departure_at=data.departure_at,
        arrival_at=data.arrival_at,
        origin_iata=data.origin_iata,
        destination_iata=data.destination_iata,
        carrier_code=data.carrier_code,
        flight_number=data.flight_number,
        base_price=data.base_price,
        currency=data.currency,
        total_seats=None,
    )

    taken = await collect_taken_seats_on_flight(db, flight_id=flight.id)
    for seat in normalized_seats:
        if seat in taken:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Seat already taken",
            )

    now = datetime.now(UTC)
    session = CheckoutSession(
        user_id=user_id,
        flight_id=flight.id,
        seats=normalized_seats,
        adults_count=data.adults,
        cabin_class=data.cabin_class,
        total_price=data.total_price if data.total_price is not None else data.base_price,
        currency=(data.currency.upper() if data.currency else None),
        status=CheckoutSessionStatus.OPEN.value,
        expires_at=now + timedelta(minutes=CHECKOUT_TTL_MINUTES),
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)

    result = await db.execute(
        select(CheckoutSession)
        .options(selectinload(CheckoutSession.flight))
        .where(CheckoutSession.id == session.id),
    )
    return CheckoutSessionDetailRead.from_orm_session(result.scalar_one())


async def get_checkout_session_detail(
    db: AsyncSession,
    *,
    session_id: int,
    user_id: int,
) -> CheckoutSessionDetailRead:
    session = await _load_owned_session(db, session_id=session_id, user_id=user_id)
    if not _session_is_active(session) and session.status == CheckoutSessionStatus.OPEN.value:
        session.status = CheckoutSessionStatus.EXPIRED.value
        await db.commit()
        await db.refresh(session)
    return CheckoutSessionDetailRead.from_orm_session(session)


async def submit_session_passengers(
    db: AsyncSession,
    *,
    session_id: int,
    user_id: int,
    body: PassengerDetailsSubmit,
) -> CheckoutSessionDetailRead:
    session = await _load_owned_session(db, session_id=session_id, user_id=user_id)
    if not _session_is_active(session):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Checkout session expired",
        )
    if session.passengers_json is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Passenger details already submitted",
        )
    if len(body.passengers) != session.adults_count:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Expected {session.adults_count} passenger(s)",
        )

    reserved_seats = {normalize_seat(seat) for seat in session.seats or []}
    today = datetime.now(UTC).date()
    seen_passports: set[str] = set()
    seen_seats: set[str] = set()
    serialized: list[dict] = []

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
            flight_id=session.flight_id,
            passport_number=passport,
            exclude_reservation_id=None,
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

        if p.passport_expiry <= today:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Passport must be valid (expiry in the future)",
            )

        serialized.append(
            {
                "title": p.title.upper(),
                "given_name": p.given_name.strip().upper(),
                "family_name": p.family_name.strip().upper(),
                "date_of_birth": p.date_of_birth.isoformat(),
                "gender": p.gender.upper(),
                "nationality": p.nationality.upper(),
                "passport_number": p.passport_number.strip().upper(),
                "passport_expiry": p.passport_expiry.isoformat(),
                "passport_issuing_country": p.passport_issuing_country.upper(),
                "seat": seat,
            },
        )

    session.passengers_json = serialized
    await db.commit()

    result = await db.execute(
        select(CheckoutSession)
        .options(selectinload(CheckoutSession.flight))
        .where(CheckoutSession.id == session.id),
    )
    return CheckoutSessionDetailRead.from_orm_session(result.scalar_one())


async def materialize_paid_reservation(
    db: AsyncSession,
    *,
    session: CheckoutSession,
    payment: Payment,
) -> Reservation:
    if session.status == CheckoutSessionStatus.CONSUMED.value and session.reservation_id:
        result = await db.execute(
            select(Reservation)
            .options(
                selectinload(Reservation.flight),
                selectinload(Reservation.ticket),
                selectinload(Reservation.passengers),
            )
            .where(Reservation.id == session.reservation_id),
        )
        reservation = result.scalar_one_or_none()
        if reservation is None:
            raise HTTPException(status_code=500, detail="Consumed session missing reservation")
        return reservation

    if session.passengers_json is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passenger details required before payment",
        )
    if not _session_is_active(session) and session.status != CheckoutSessionStatus.OPEN.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Checkout session is no longer valid",
        )

    result = await db.execute(
        select(CheckoutSession)
        .options(selectinload(CheckoutSession.flight))
        .where(CheckoutSession.id == session.id),
    )
    session = result.scalar_one()
    flight = session.flight
    if flight is None:
        raise HTTPException(status_code=500, detail="Checkout session flight missing")

    normalized_seats = [normalize_seat(seat) for seat in session.seats or []]
    primary_seat = normalized_seats[0]
    taken = await collect_taken_seats_on_flight(db, flight_id=flight.id, exclude_session_id=session.id)
    for seat in normalized_seats:
        if seat in taken:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Seat no longer available",
            )

    reservation = Reservation(
        user_id=session.user_id,
        flight_id=flight.id,
        seat=primary_seat,
        status=ReservationStatus.PAID.value,
        total_price=session.total_price or Decimal("0.00"),
        currency=session.currency,
        adults_count=session.adults_count,
        cabin_class=session.cabin_class,
        pnr=generate_pnr(),
        passenger_details_completed_at=datetime.now(UTC),
    )
    db.add(reservation)
    await db.flush()

    for idx, seat_code in enumerate(normalized_seats, start=1):
        db.add(
            ReservationSeat(
                reservation_id=reservation.id,
                flight_id=flight.id,
                seat=seat_code,
                sequence=idx,
            ),
        )

    ticket_number = generate_eticket_number(flight.carrier_code)
    qr_plain = qr_content_for_ticket(
        ticket_number,
        flight_id=flight.id,
        origin_iata=flight.origin_iata,
        destination_iata=flight.destination_iata,
        departure_at=flight.departure_at.isoformat(),
        carrier_code=flight.carrier_code,
        flight_number=flight.flight_number,
        seat=primary_seat,
        pnr=reservation.pnr,
        carrier_name=carrier_name(flight.carrier_code),
    )
    filename = f"{ticket_number.replace('-', '')}.png"
    qr_path = write_qr_png(qr_plain, filename)

    ticket = Ticket(
        booking_id=reservation.id,
        ticket_number=ticket_number,
        ordered_by_user_id=session.user_id,
        qr_code=qr_plain,
        qr_image_path=qr_path,
        status=TicketStatus.PENDING_PASSENGER.value,
    )
    db.add(ticket)
    await db.flush()

    for idx, row in enumerate(session.passengers_json or [], start=1):
        db.add(
            BookingPassenger(
                reservation_id=reservation.id,
                sequence=idx,
                ordered_by_user_id=session.user_id,
                title=row["title"],
                given_name=row["given_name"],
                family_name=row["family_name"],
                date_of_birth=date.fromisoformat(row["date_of_birth"]),
                gender=row["gender"],
                nationality=row["nationality"],
                passport_number=row["passport_number"],
                passport_expiry=date.fromisoformat(row["passport_expiry"]),
                passport_issuing_country=row["passport_issuing_country"],
                seat=row["seat"],
            ),
        )

    await db.flush()

    result = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
            selectinload(Reservation.passengers),
        )
        .where(Reservation.id == reservation.id),
    )
    reservation = result.scalar_one()
    activate_all_passenger_tickets(reservation)

    session.status = CheckoutSessionStatus.CONSUMED.value
    session.reservation_id = reservation.id
    payment.reservation_id = reservation.id

    return reservation
