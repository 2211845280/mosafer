"""Pydantic schemas for airports."""

from datetime import datetime
<<<<<<< HEAD
from typing import Any
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

from pydantic import BaseModel, ConfigDict, Field


class AirportCreate(BaseModel):
    iata_code: str = Field(..., min_length=3, max_length=3)
    name: str
    city: str
    country: str
    timezone: str | None = None
<<<<<<< HEAD
    latitude: float | None = None
    longitude: float | None = None
    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767


class AirportUpdate(BaseModel):
    name: str | None = None
    city: str | None = None
    country: str | None = None
    timezone: str | None = None
<<<<<<< HEAD
    latitude: float | None = None
    longitude: float | None = None
    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767


class AirportRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    iata_code: str
    name: str
    city: str
    country: str
    timezone: str | None = None
<<<<<<< HEAD
    latitude: float | None = None
    longitude: float | None = None
    created_at: datetime


class AirportDetailRead(AirportRead):
    """Extended airport read with terminal/amenity details."""

    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None
=======
    created_at: datetime
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
