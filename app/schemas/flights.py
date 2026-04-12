"""Pydantic schemas for flights."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.airports import AirportRead


class FlightCreate(BaseModel):
<<<<<<< HEAD
    provider_flight_id: str = Field(..., min_length=1, max_length=128)
=======
    amadeus_flight_id: str = Field(..., min_length=1, max_length=128)
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
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
<<<<<<< HEAD
    provider_flight_id: str | None = Field(None, min_length=1, max_length=128)
=======
    amadeus_flight_id: str | None = Field(None, min_length=1, max_length=128)
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
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
<<<<<<< HEAD
    provider_flight_id: str
=======
    amadeus_flight_id: str
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
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


<<<<<<< HEAD
class FlightOfferRead(BaseModel):
    offer_id: str
    provider_flight_id: str
=======
class AmadeusFlightOfferRead(BaseModel):
    offer_id: str
    amadeus_flight_id: str
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    origin_iata: str
    destination_iata: str
    carrier_code: str
    flight_number: str
    departure_at: datetime
    arrival_at: datetime
    total_price: Decimal | None = None
    currency: str | None = None
<<<<<<< HEAD
    source: str = "mock"


class FlightSearchResponse(BaseModel):
    items: list[FlightOfferRead]
=======


class FlightSearchResponse(BaseModel):
    items: list[AmadeusFlightOfferRead]
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    total: int
    skip: int
    limit: int
