"""Pydantic schemas for flights."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.airports import AirportRead


class FlightCreate(BaseModel):
    flight_number: str = Field(..., min_length=1, max_length=32)
    origin_airport_id: int
    destination_airport_id: int
    departure_at: datetime
    arrival_at: datetime
    base_price: Decimal = Field(..., ge=0)
    total_seats: int = Field(..., ge=1)


class FlightUpdate(BaseModel):
    flight_number: str | None = Field(None, min_length=1, max_length=32)
    origin_airport_id: int | None = None
    destination_airport_id: int | None = None
    departure_at: datetime | None = None
    arrival_at: datetime | None = None
    base_price: Decimal | None = Field(None, ge=0)
    total_seats: int | None = Field(None, ge=1)


class FlightRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    flight_number: str
    origin_airport_id: int
    destination_airport_id: int
    departure_at: datetime
    arrival_at: datetime
    base_price: Decimal
    total_seats: int
    created_at: datetime


class FlightDetailRead(FlightRead):
    origin_airport: AirportRead
    destination_airport: AirportRead


class FlightSearchResponse(BaseModel):
    items: list[FlightRead]
    total: int
    skip: int
    limit: int
