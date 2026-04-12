"""Pydantic schemas for flight status."""

from __future__ import annotations

from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel


class FlightStatusCode(StrEnum):
    scheduled = "scheduled"
    check_in_open = "check_in_open"
    boarding = "boarding"
    departed = "departed"
    landed = "landed"
    canceled = "canceled"
    delayed = "delayed"


class FlightStatusRead(BaseModel):
    flight_number: str
    carrier_code: str
    departure_gate: str | None = None
    arrival_gate: str | None = None
    terminal: str | None = None
    check_in_counter: str | None = None
    delay_minutes: int = 0
    status: FlightStatusCode
    updated_at: datetime
