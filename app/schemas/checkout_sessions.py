"""Pydantic schemas for checkout sessions."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.data.airlines import carrier_name
from app.schemas.booking_passengers import BookingPassengerCreate
from app.schemas.flights import FlightRead
from app.schemas.reservations import ReservationCreate


class CheckoutSessionCreate(ReservationCreate):
    """Same payload as reservation create (seat selection step)."""


class CheckoutSessionRead(BaseModel):
    id: int
    user_id: int
    flight_id: int
    seats: list[str]
    adults_count: int
    cabin_class: str | None = None
    total_price: Decimal | None = None
    currency: str | None = None
    status: str
    passengers_submitted: bool = False
    expires_at: datetime
    created_at: datetime
    reservation_id: int | None = None


class CheckoutSessionDetailRead(CheckoutSessionRead):
    flight: FlightRead
    carrier_name: str | None = None
    passenger_details_required: bool = True

    @classmethod
    def from_orm_session(cls, session) -> "CheckoutSessionDetailRead":
        flight = session.flight
        return cls(
            id=session.id,
            user_id=session.user_id,
            flight_id=session.flight_id,
            seats=list(session.seats or []),
            adults_count=session.adults_count,
            cabin_class=session.cabin_class,
            total_price=session.total_price,
            currency=session.currency,
            status=session.status,
            passengers_submitted=session.passengers_json is not None,
            expires_at=session.expires_at,
            created_at=session.created_at,
            reservation_id=session.reservation_id,
            flight=FlightRead.model_validate(flight),
            carrier_name=carrier_name(flight.carrier_code) if flight else None,
            passenger_details_required=session.passengers_json is None,
        )


class CheckoutPassengerDetailsSubmit(BaseModel):
    passengers: list[BookingPassengerCreate] = Field(..., min_length=1, max_length=9)
