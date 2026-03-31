"""Reservation (booking) API."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission, require_permission
from app.core.ticket_qr import build_qr_payload, write_qr_png
from app.db.database import get_db
from app.models.flights import Flight
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.flights import FlightRead
from app.schemas.reservations import ReservationCreate, ReservationRead, ReservationWithFlightRead
from app.services.booking_utils import is_valid_seat, normalize_seat

router = APIRouter()


@router.post(
    "/reservations",
    response_model=ReservationWithFlightRead,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def create_reservation(
    data: ReservationCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ReservationWithFlightRead:
    """Create booking from selected offer; upserts local flight and issues ticket."""
    seat = normalize_seat(data.seat)
    if not is_valid_seat(seat):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid seat format (use row 1-99 and letter A-F, e.g. 12A)",
        )

    flight_result = await db.execute(
        select(Flight).where(Flight.amadeus_flight_id == data.amadeus_flight_id.strip()),
    )
    flight = flight_result.scalar_one_or_none()
    if flight is None:
        flight = Flight(
            amadeus_flight_id=data.amadeus_flight_id.strip(),
            origin_iata=data.origin_iata.upper(),
            destination_iata=data.destination_iata.upper(),
            carrier_code=data.carrier_code.upper(),
            flight_number=data.flight_number.strip(),
            departure_at=data.departure_at,
            arrival_at=data.arrival_at,
            base_price=data.base_price,
            currency=data.currency.upper() if data.currency else None,
            total_seats=None,
        )
        db.add(flight)
        await db.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat=seat,
        status=ReservationStatus.BOOKED.value,
        total_price=data.total_price if data.total_price is not None else data.base_price,
        currency=(data.currency.upper() if data.currency else None),
    )
    db.add(reservation)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Seat already taken",
        ) from None

    ticket_number = uuid.uuid4().hex[:16].upper()
    payload = build_qr_payload(ticket_number, reservation.id)
    filename = f"{ticket_number}.png"
    qr_path = write_qr_png(payload, filename)

    ticket = Ticket(
        reservation_id=reservation.id,
        ticket_number=ticket_number,
        qr_payload=payload,
        qr_image_path=qr_path,
        status=TicketStatus.ISSUED.value,
    )
    db.add(ticket)
    await db.commit()
    await db.refresh(reservation)
    await db.refresh(flight)

    return ReservationWithFlightRead(
        id=reservation.id,
        user_id=reservation.user_id,
        flight_id=reservation.flight_id,
        seat=reservation.seat,
        status=reservation.status,
        total_price=reservation.total_price,
        currency=reservation.currency,
        created_at=reservation.created_at,
        flight=FlightRead.model_validate(flight),
    )


@router.get(
    "/reservations/me",
    response_model=list[ReservationWithFlightRead],
    dependencies=[Depends(require_permission("flights.read"))],
)
async def list_my_reservations(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[ReservationWithFlightRead]:
    """List current user's reservations with flight info."""
    result = await db.execute(
        select(Reservation)
        .options(selectinload(Reservation.flight))
        .where(Reservation.user_id == user.id)
        .order_by(Reservation.created_at.desc()),
    )
    rows = result.scalars().all()
    out: list[ReservationWithFlightRead] = []
    for r in rows:
        out.append(
            ReservationWithFlightRead(
                id=r.id,
                user_id=r.user_id,
                flight_id=r.flight_id,
                seat=r.seat,
                status=r.status,
                created_at=r.created_at,
                flight=FlightRead.model_validate(r.flight),
            ),
        )
    return out


@router.post(
    "/reservations/{reservation_id}/cancel",
    response_model=ReservationRead,
    dependencies=[Depends(require_permission("bookings.cancel"))],
)
async def cancel_reservation(
    reservation_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ReservationRead:
    """Cancel booking (owner or admin)."""
    result = await db.execute(
        select(Reservation).where(Reservation.id == reservation_id),
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")

    if reservation.user_id != user.id:
        await assert_user_has_permission(db, user, "users.admin.manage")

    if reservation.status == ReservationStatus.CANCELED.value:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already cancelled")
    if reservation.status == ReservationStatus.PAID.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Paid booking cannot be canceled in Epic 2",
        )

    reservation.status = ReservationStatus.CANCELED.value
    ticket_r = await db.execute(select(Ticket).where(Ticket.reservation_id == reservation.id))
    ticket = ticket_r.scalar_one_or_none()
    if ticket is not None:
        ticket.status = TicketStatus.CANCELLED.value

    await db.commit()
    await db.refresh(reservation)
    return ReservationRead.model_validate(reservation)
