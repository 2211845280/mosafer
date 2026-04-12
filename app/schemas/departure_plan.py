"""Pydantic schemas for the Smart Airport Timer (Epic 4)."""

from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

# ---------------------------------------------------------------------------
# Directions
# ---------------------------------------------------------------------------


class TransportMode(StrEnum):
    driving = "driving"
    transit = "transit"
    walking = "walking"
    taxi = "taxi"


class TrafficLevel(StrEnum):
    low = "low"
    moderate = "moderate"
    heavy = "heavy"


class DirectionsResult(BaseModel):
    travel_minutes: int
    distance_km: float
    mode: TransportMode
    traffic_level: TrafficLevel


# ---------------------------------------------------------------------------
# Weather
# ---------------------------------------------------------------------------


class WeatherCondition(StrEnum):
    clear = "clear"
    cloudy = "cloudy"
    rain = "rain"
    snow = "snow"
    storm = "storm"


class WeatherResult(BaseModel):
    condition: WeatherCondition
    temperature_c: float
    visibility_km: float
    severe_alert: bool = False
    description: str


# ---------------------------------------------------------------------------
# Departure Plan
# ---------------------------------------------------------------------------


class DeparturePlanResult(BaseModel):
    leave_at: datetime
    travel_minutes: int
    distance_km: float
    check_in_buffer_minutes: int
    weather_buffer_minutes: int
    weather: WeatherResult
    transport_mode: TransportMode
    traffic_level: TrafficLevel
    flight_departure_at: datetime


# ---------------------------------------------------------------------------
# Location Check (At-Airport trigger)
# ---------------------------------------------------------------------------


class LocationCheckRequest(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)


class FlightStatusSummary(BaseModel):
    """Minimal flight status for location-check response."""

    flight_number: str
    carrier_code: str
    departure_gate: str | None = None
    terminal: str | None = None
    status: str
    delay_minutes: int = 0


class AirportContextRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    iata_code: str
    name: str
    terminal_info: dict[str, Any] | None = None
    amenities: dict[str, Any] | None = None
    map_url: str | None = None


class LocationCheckResponse(BaseModel):
    at_airport: bool
    distance_km: float
    flight_status: FlightStatusSummary | None = None
    airport: AirportContextRead | None = None
    minutes_to_boarding: int | None = None
    departure_plan: DeparturePlanResult | None = None


# ---------------------------------------------------------------------------
# Epic 6 — In-Airport Experience
# ---------------------------------------------------------------------------


class GateSuggestionLevel(StrEnum):
    explore = "explore"
    move_near_gate = "move_near_gate"
    proceed_now = "proceed_now"


class GateSuggestion(BaseModel):
    level: GateSuggestionLevel
    message: str


class BoardingCountdown(BaseModel):
    boarding_at: datetime
    minutes_to_boarding: int
    is_boarding_open: bool


class ArrivalContextRead(BaseModel):
    airport: AirportContextRead
    immigration_tip: str
    baggage_claim: str | None = None
    local_transport_options: list[str] = []
    destination_tips: list[str] = []


class AirportDashboardResponse(BaseModel):
    reservation_id: int
    at_airport: bool
    distance_km: float
    flight_status: FlightStatusSummary
    airport: AirportContextRead
    boarding: BoardingCountdown
    walking_time_to_gate_minutes: int
    nearby_food_shops: list[str] = []
    gate_suggestion: GateSuggestion
    arrival_context: ArrivalContextRead | None = None
