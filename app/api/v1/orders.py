"""Order (purchase) API — creates reservation + ticket from a mock flight offer."""

import uuid
from datetime import datetime, timedelta
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.core.rbac import require_permission
from app.core.ticket_qr import qr_content_for_ticket, write_qr_png
from app.db.database import get_db
from app.models.flights import Flight
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.orders import OrderCreateRequest, OrderResponse
from app.schemas.tickets import FlightSummaryForTicket
from app.services.booking_utils import is_valid_seat, normalize_seat
from app.services.external.mock_flight_service import MockFlightService

router = APIRouter()
_mock_service = MockFlightService()


@router.post(
    "/orders",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("bookings.create"))],
)
async def create_order(
    data: OrderCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> OrderResponse:
    """Purchase a flight offer: creates reservation (paid) + ticket + QR."""
    seat = normalize_seat(data.seat)
    if not is_valid_seat(seat):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid seat format (use row 1-99 and letter A-F, e.g. 12A)",
        )

    offer = await _mock_service.get_offer_by_id(data.offer_id)
    if offer is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Offer not found",
        )

    dep_h, dep_m = (int(p) for p in offer["departure_time"].split(":"))
    now = datetime.utcnow()
    departure_at = datetime(now.year, now.month, now.day, dep_h, dep_m)
    if departure_at < now:
        departure_at += timedelta(days=1)
    arrival_at = departure_at + timedelta(hours=offer["duration_hours"])

    result = await db.execute(
        select(Flight).where(Flight.provider_flight_id == offer["provider_flight_id"])
    )
    flight = result.scalar_one_or_none()
    if flight is None:
        flight = Flight(
            provider_flight_id=offer["provider_flight_id"],
            origin_iata=offer["origin_iata"],
            destination_iata=offer["destination_iata"],
            carrier_code=offer["carrier_code"],
            flight_number=offer["flight_number"],
            departure_at=departure_at,
            arrival_at=arrival_at,
            base_price=Decimal(offer["total_price"]),
            currency=offer["currency"],
        )
        db.add(flight)
        await db.flush()

    reservation = Reservation(
        user_id=user.id,
        flight_id=flight.id,
        seat=seat,
        status=ReservationStatus.PAID.value,
        total_price=Decimal(offer["total_price"]),
        currency=offer["currency"],
    )
    db.add(reservation)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Seat already taken on this flight",
        ) from None

    ticket_number = uuid.uuid4().hex[:16].upper()
    qr_plain = qr_content_for_ticket(
        ticket_number,
        flight_id=flight.id,
        origin_iata=flight.origin_iata,
        destination_iata=flight.destination_iata,
        departure_at=flight.departure_at.isoformat(),
        carrier_code=flight.carrier_code,
        flight_number=flight.flight_number,
        seat=seat,
    )
    filename = f"{ticket_number}.png"
    qr_path = write_qr_png(qr_plain, filename)

    ticket = Ticket(
        booking_id=reservation.id,
        ticket_number=ticket_number,
        qr_code=qr_plain,
        qr_image_path=qr_path,
        status=TicketStatus.VALID.value,
    )
    db.add(ticket)
    await db.commit()
    await db.refresh(reservation)
    await db.refresh(flight)

    return OrderResponse(
        reservation_id=reservation.id,
        ticket_number=ticket_number,
        qr_image_path=qr_path,
        flight=FlightSummaryForTicket(
            carrier_code=flight.carrier_code,
            flight_number=flight.flight_number,
            origin_iata=flight.origin_iata,
            destination_iata=flight.destination_iata,
            departure_at=flight.departure_at,
            arrival_at=flight.arrival_at,
            seat=seat,
        ),
        total_price=reservation.total_price,
        currency=reservation.currency,
        status=reservation.status,
        created_at=reservation.created_at,
    )
