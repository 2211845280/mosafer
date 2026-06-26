"""Reservation (booking) API."""

from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response, status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.jwt import get_current_user
from app.core.rbac import assert_user_has_permission, require_permission
from app.core.ticket_qr import qr_content_for_ticket, write_qr_png
from app.data.airlines import carrier_name
from app.db.database import get_db
from app.models.booking_passengers import BookingPassenger
from app.models.reservations import Reservation, ReservationStatus
from app.models.reservation_seats import ReservationSeat
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.blocked_passports import BlockedPassportsRead
from app.schemas.booking_passengers import PassengerDetailsSubmit
from app.schemas.flights import FlightRead
from app.schemas.pagination import PaginatedResponse
from app.schemas.reservations import (
    CancelReservationResponse,
    ReservationCreate,
    ReservationDetailRead,
    ReservationRead,
    ReservationWithFlightRead,
    seats_for_reservation,
)
from app.services.booking_reference import generate_eticket_number
from app.services.booking_utils import is_valid_seat, normalize_seat
from app.services.flight_identity import resolve_flight_for_booking
from app.services.passenger_details_service import get_reservation_detail, submit_passenger_details
from app.services.passenger_duplicate import list_blocked_passports_on_flight
from app.services.reservation_cancel_service import cancel_reservation_with_refund

router = APIRouter()


def _is_past_departure(departure_at: datetime) -> bool:
    now = datetime.now(UTC)
    today = datetime(now.year, now.month, now.day, tzinfo=UTC)
    dep = departure_at if departure_at.tzinfo else departure_at.replace(tzinfo=UTC)
    dep_day = datetime(dep.year, dep.month, dep.day, tzinfo=UTC)
    return dep_day < today


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
    """Create booking from selected offer; upserts local flight and issues provisional ticket."""
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

    primary_seat = normalized_seats[0]
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

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat=primary_seat,
        status=ReservationStatus.BOOKED.value,
        total_price=data.total_price if data.total_price is not None else data.base_price,
        currency=(data.currency.upper() if data.currency else None),
        adults_count=data.adults,
        cabin_class=data.cabin_class,
    )
    db.add(reservation)
    try:
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
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Seat already taken",
        ) from None

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
        carrier_name=carrier_name(flight.carrier_code),
    )
    filename = f"{ticket_number.replace('-', '')}.png"
    qr_path = write_qr_png(qr_plain, filename)

    ticket = Ticket(
        booking_id=reservation.id,
        ticket_number=ticket_number,
        ordered_by_user_id=user.id,
        qr_code=qr_plain,
        qr_image_path=qr_path,
        status=TicketStatus.PENDING_PASSENGER.value,
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
        adults_count=reservation.adults_count,
        pnr=reservation.pnr,
        cabin_class=reservation.cabin_class,
        passenger_details_completed_at=reservation.passenger_details_completed_at,
        created_at=reservation.created_at,
        flight=FlightRead.model_validate(flight),
        ticket_number=ticket_number,
        ticket_status=TicketStatus.PENDING_PASSENGER.value,
        carrier_name=carrier_name(flight.carrier_code),
    )


@router.get(
    "/reservations/me",
    response_model=PaginatedResponse[ReservationWithFlightRead],
    dependencies=[Depends(require_permission("flights.read"))],
)
async def list_my_reservations(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[ReservationWithFlightRead]:
    """List trips owned by the user or permanently claimed via ticket QR."""
    claimed_passenger_reservations = select(BookingPassenger.reservation_id).where(
        BookingPassenger.assigned_to_user_id == user.id,
    )
    claimed_ticket_reservations = select(Ticket.booking_id).where(
        Ticket.assigned_to_user_id == user.id,
    )
    user_can_view = or_(
        Reservation.user_id == user.id,
        Reservation.id.in_(claimed_passenger_reservations),
        Reservation.id.in_(claimed_ticket_reservations),
    )
    visible = (
        user_can_view,
        Reservation.hidden_at.is_(None),
    )
    total = (
        await db.execute(
            select(func.count())
            .select_from(Reservation)
            .where(*visible)
        )
    ).scalar_one()

    offset = (page - 1) * page_size
    result = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
            selectinload(Reservation.passengers),
            selectinload(Reservation.reservation_seats),
        )
        .where(*visible)
        .order_by(Reservation.created_at.desc())
        .offset(offset)
        .limit(page_size),
    )
    items: list[ReservationWithFlightRead] = []
    for r in result.scalars().all():
        claimed_passengers = [
            passenger
            for passenger in sorted(r.passengers, key=lambda row: row.sequence)
            if passenger.assigned_to_user_id == user.id
        ]
        claimed_passenger = claimed_passengers[0] if claimed_passengers else None
        is_owner = r.user_id == user.id
        visible_seat = (
            (claimed_passenger.seat or r.seat)
            if claimed_passenger is not None and not is_owner
            else r.seat
        )
        visible_ticket_number = (
            claimed_passenger.passenger_ticket_number
            if claimed_passenger is not None and not is_owner
            else (r.ticket.ticket_number if r.ticket else None)
        )
        visible_qr_code = (
            claimed_passenger.qr_code
            if claimed_passenger is not None and not is_owner
            else (r.ticket.qr_code if r.ticket else None)
        )
        items.append(
            ReservationWithFlightRead(
                id=r.id,
                user_id=r.user_id,
                flight_id=r.flight_id,
                seat=visible_seat,
                status=r.status,
                total_price=r.total_price,
                currency=r.currency,
                adults_count=r.adults_count if is_owner else 1,
                pnr=r.pnr,
                cabin_class=r.cabin_class,
                passenger_details_completed_at=r.passenger_details_completed_at,
                created_at=r.created_at,
                flight=FlightRead.model_validate(r.flight),
                ticket_number=visible_ticket_number,
                ticket_status=r.ticket.status if r.ticket else None,
                carrier_name=carrier_name(r.flight.carrier_code),
                qr_code=visible_qr_code,
                seats=seats_for_reservation(r) if is_owner else [visible_seat],
            ),
        )
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


@router.get(
    "/reservations/{reservation_id}",
    response_model=ReservationDetailRead,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def read_reservation(
    reservation_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ReservationDetailRead:
    return await get_reservation_detail(db, reservation_id=reservation_id, user_id=user.id)


@router.post(
    "/reservations/{reservation_id}/hide",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("flights.read"))],
)
async def hide_reservation(
    reservation_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Response:
    """Hide a canceled or past reservation from the user's trip list."""
    result = await db.execute(
        select(Reservation)
        .options(selectinload(Reservation.flight))
        .where(Reservation.id == reservation_id),
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    if reservation.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your reservation")

    if reservation.hidden_at is not None:
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    is_canceled = reservation.status == ReservationStatus.CANCELED.value
    is_past = _is_past_departure(reservation.flight.departure_at)
    if not is_canceled and not is_past:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only hide canceled or past reservations",
        )

    reservation.hidden_at = datetime.now(UTC)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/reservations/{reservation_id}/blocked-passports",
    response_model=BlockedPassportsRead,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def read_blocked_passports(
    reservation_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> BlockedPassportsRead:
    """Return passport numbers already booked on this reservation's flight."""
    result = await db.execute(select(Reservation).where(Reservation.id == reservation_id))
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")
    if reservation.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your reservation")

    blocked = await list_blocked_passports_on_flight(db, flight_id=reservation.flight_id)
    return BlockedPassportsRead(blocked_passports=blocked)


@router.post(
    "/reservations/{reservation_id}/passenger-details",
    response_model=ReservationDetailRead,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def post_passenger_details(
    reservation_id: int,
    body: PassengerDetailsSubmit,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ReservationDetailRead:
    return await submit_passenger_details(
        db,
        reservation_id=reservation_id,
        user_id=user.id,
        body=body,
    )


@router.post(
    "/reservations/{reservation_id}/cancel",
    response_model=CancelReservationResponse,
    dependencies=[Depends(require_permission("bookings.cancel"))],
)
async def cancel_reservation(
    reservation_id: int,
    request: Request,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CancelReservationResponse:
    """Cancel booking (owner or admin) with refund rules for paid bookings."""
    result = await db.execute(
        select(Reservation).where(Reservation.id == reservation_id),
    )
    reservation = result.scalar_one_or_none()
    if reservation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation not found")

    if reservation.user_id != user.id:
        await assert_user_has_permission(db, user, "users.admin.manage")

    locale = (request.headers.get("accept-language") or "en").split(",")[0].strip()

    cancel_result = await cancel_reservation_with_refund(
        db,
        reservation_id=reservation_id,
        locale=locale,
    )
    return CancelReservationResponse(
        reservation=ReservationRead.model_validate(cancel_result.reservation),
        refunded_amount=cancel_result.refunded_amount,
        penalty_amount=cancel_result.penalty_amount,
        currency=cancel_result.currency,
        refund_type=cancel_result.refund_type,
    )
