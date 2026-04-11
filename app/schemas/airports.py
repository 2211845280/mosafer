"""Pydantic schemas for airports."""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class AirportCreate(BaseModel):
    iata_code: str = Field(..., min_length=3, max_length=3)
    name: str
    city: str
    country: str
    timezone: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None


class AirportUpdate(BaseModel):
    name: str | None = None
    city: str | None = None
    country: str | None = None
    timezone: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None


class AirportRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    iata_code: str
    name: str
    city: str
    country: str
    timezone: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    created_at: datetime


class AirportDetailRead(AirportRead):
    """Extended airport read with terminal/amenity details."""

    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None
