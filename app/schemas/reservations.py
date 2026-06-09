"""Pydantic schemas for reservations."""

from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.data.airlines import carrier_name
from app.schemas.booking_passengers import BookingPassengerRead
from app.schemas.flights import FlightRead


class ReservationCreate(BaseModel):
    provider_flight_id: str = Field(..., min_length=1, max_length=128)
    origin_iata: str = Field(..., min_length=3, max_length=3)
    destination_iata: str = Field(..., min_length=3, max_length=3)
    carrier_code: str = Field(..., min_length=2, max_length=3)
    flight_number: str = Field(..., min_length=1, max_length=32)
    departure_at: datetime
    arrival_at: datetime
    base_price: Decimal | None = Field(None, ge=0)
    currency: str | None = Field(None, min_length=3, max_length=3)
    seat: str | None = Field(None, min_length=1, max_length=8)
    seats: list[str] | None = Field(None, min_length=1, max_length=9)
    total_price: Decimal | None = Field(None, ge=0)
    adults: int = Field(1, ge=1, le=9)
    cabin_class: str | None = Field(None, max_length=32)

    @model_validator(mode="after")
    def normalize_seats(self) -> "ReservationCreate":
        if self.seats:
            resolved = self.seats
        elif self.seat:
            resolved = [self.seat]
        else:
            raise ValueError("Either seats or seat is required")
        if len(resolved) != self.adults:
            raise ValueError(f"Expected {self.adults} seat(s), got {len(resolved)}")
        object.__setattr__(self, "seats", resolved)
        object.__setattr__(self, "seat", resolved[0])
        return self


class ReservationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    flight_id: int
    seat: str
    status: str
    total_price: Decimal | None = None
    currency: str | None = None
    adults_count: int = 1
    pnr: str | None = None
    cabin_class: str | None = None
    passenger_details_completed_at: datetime | None = None
    created_at: datetime


def seats_for_reservation(reservation) -> list[str]:
    """All seats on a booking, ordered by reservation_seats.sequence."""
    seat_rows = getattr(reservation, "reservation_seats", None) or []
    if seat_rows:
        return [
            row.seat
            for row in sorted(seat_rows, key=lambda r: r.sequence)
        ]
    return [reservation.seat]


class ReservationWithFlightRead(ReservationRead):
    flight: FlightRead
    ticket_number: str | None = None
    ticket_status: str | None = None
    carrier_name: str | None = None
    qr_code: str | None = None
    seats: list[str] = Field(default_factory=list)


class ReservationDetailRead(ReservationWithFlightRead):
    passengers: list[BookingPassengerRead] = Field(default_factory=list)
    passenger_details_required: bool = False

    @classmethod
    def from_orm_reservation(cls, reservation) -> "ReservationDetailRead":
        flight = reservation.flight
        ticket = reservation.ticket
        completed = reservation.passenger_details_completed_at is not None
        paid = reservation.status == "paid"
        booked = reservation.status == "booked"
        seats = seats_for_reservation(reservation)
        return cls(
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
            ticket_number=ticket.ticket_number if ticket else None,
            ticket_status=ticket.status if ticket else None,
            carrier_name=carrier_name(flight.carrier_code),
            qr_code=ticket.qr_code if ticket else None,
            passengers=[BookingPassengerRead.model_validate(p) for p in reservation.passengers],
            passenger_details_required=(booked or paid) and not completed,
            seats=seats,
        )


class CancelReservationResponse(BaseModel):
    reservation: ReservationRead
    refunded_amount: Decimal | None = None
    penalty_amount: Decimal | None = None
    currency: str | None = None
    refund_type: Literal["none", "full", "partial"]
