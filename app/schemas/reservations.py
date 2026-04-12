"""Pydantic schemas for reservations."""

from datetime import datetime
<<<<<<< HEAD
from decimal import Decimal
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.flights import FlightRead


class ReservationCreate(BaseModel):
<<<<<<< HEAD
    provider_flight_id: str = Field(..., min_length=1, max_length=128)
=======
    amadeus_flight_id: str = Field(..., min_length=1, max_length=128)
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    origin_iata: str = Field(..., min_length=3, max_length=3)
    destination_iata: str = Field(..., min_length=3, max_length=3)
    carrier_code: str = Field(..., min_length=2, max_length=3)
    flight_number: str = Field(..., min_length=1, max_length=32)
    departure_at: datetime
    arrival_at: datetime
<<<<<<< HEAD
    base_price: Decimal | None = Field(None, ge=0)
    currency: str | None = Field(None, min_length=3, max_length=3)
    seat: str = Field(..., min_length=1, max_length=8)
    total_price: Decimal | None = Field(None, ge=0)
=======
    base_price: float | None = Field(None, ge=0)
    currency: str | None = Field(None, min_length=3, max_length=3)
    seat: str = Field(..., min_length=1, max_length=8)
    total_price: float | None = Field(None, ge=0)
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767


class ReservationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    flight_id: int
    seat: str
    status: str
<<<<<<< HEAD
    total_price: Decimal | None = None
=======
    total_price: float | None = None
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    currency: str | None = None
    created_at: datetime


class ReservationWithFlightRead(ReservationRead):
    flight: FlightRead
