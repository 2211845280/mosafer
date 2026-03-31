"""Pydantic schemas for reservations."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.flights import FlightRead


class ReservationCreate(BaseModel):
    flight_id: int
    seat: str = Field(..., min_length=1, max_length=8)


class ReservationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    flight_id: int
    seat: str
    status: str
    created_at: datetime


class ReservationWithFlightRead(ReservationRead):
    flight: FlightRead
