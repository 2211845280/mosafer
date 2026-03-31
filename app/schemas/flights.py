"""Pydantic schemas for flights."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.airports import AirportRead


class FlightCreate(BaseModel):
    amadeus_flight_id: str = Field(..., min_length=1, max_length=128)
    origin_iata: str = Field(..., min_length=3, max_length=3)
    destination_iata: str = Field(..., min_length=3, max_length=3)
    carrier_code: str = Field(..., min_length=2, max_length=3)
    flight_number: str = Field(..., min_length=1, max_length=32)
    origin_airport_id: int | None = None
    destination_airport_id: int | None = None
    departure_at: datetime
    arrival_at: datetime
    base_price: Decimal | None = Field(None, ge=0)
    currency: str | None = Field(None, min_length=3, max_length=3)
    total_seats: int | None = Field(None, ge=1)


class FlightUpdate(BaseModel):
    amadeus_flight_id: str | None = Field(None, min_length=1, max_length=128)
    origin_iata: str | None = Field(None, min_length=3, max_length=3)
    destination_iata: str | None = Field(None, min_length=3, max_length=3)
    carrier_code: str | None = Field(None, min_length=2, max_length=3)
    flight_number: str | None = Field(None, min_length=1, max_length=32)
    origin_airport_id: int | None = None
    destination_airport_id: int | None = None
    departure_at: datetime | None = None
    arrival_at: datetime | None = None
    base_price: Decimal | None = Field(None, ge=0)
    currency: str | None = Field(None, min_length=3, max_length=3)
    total_seats: int | None = Field(None, ge=1)


class FlightRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    amadeus_flight_id: str
    origin_iata: str
    destination_iata: str
    carrier_code: str
    flight_number: str
    origin_airport_id: int | None
    destination_airport_id: int | None
    departure_at: datetime
    arrival_at: datetime
    base_price: Decimal | None
    currency: str | None
    total_seats: int | None
    created_at: datetime


class FlightDetailRead(FlightRead):
    origin_airport: AirportRead
    destination_airport: AirportRead


class AmadeusFlightOfferRead(BaseModel):
    offer_id: str
    amadeus_flight_id: str
    origin_iata: str
    destination_iata: str
    carrier_code: str
    flight_number: str
    departure_at: datetime
    arrival_at: datetime
    total_price: Decimal | None = None
    currency: str | None = None


class FlightSearchResponse(BaseModel):
    items: list[AmadeusFlightOfferRead]
    total: int
    skip: int
    limit: int
