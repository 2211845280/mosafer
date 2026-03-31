"""Pydantic schemas for airports."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class AirportCreate(BaseModel):
    iata_code: str = Field(..., min_length=3, max_length=3)
    name: str
    city: str
    country: str
    timezone: str | None = None


class AirportUpdate(BaseModel):
    name: str | None = None
    city: str | None = None
    country: str | None = None
    timezone: str | None = None


class AirportRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    iata_code: str
    name: str
    city: str
    country: str
    timezone: str | None = None
    created_at: datetime
