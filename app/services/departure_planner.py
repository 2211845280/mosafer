"""Departure time calculator.

Combines travel ETA, weather conditions, and check-in buffers to recommend
when a traveler should leave for the airport.
"""

from __future__ import annotations

from datetime import datetime, timedelta

import structlog

from app.schemas.departure_plan import (
    DeparturePlanResult,
    TransportMode,
    WeatherCondition,
)
from app.services.external.mock_maps_service import MockMapsService
from app.services.external.mock_weather_service import MockWeatherService

logger = structlog.get_logger(__name__)

_maps = MockMapsService()
_weather = MockWeatherService()

_DOMESTIC_BUFFER_MIN = 120
_INTERNATIONAL_BUFFER_MIN = 180


class DeparturePlanner:
    """Calculates the recommended departure time for a flight."""

    async def calculate(
        self,
        user_lat: float,
        user_lng: float,
        airport_lat: float,
        airport_lng: float,
        airport_country: str,
        origin_country: str,
        departure_at: datetime,
        transport_mode: TransportMode,
    ) -> DeparturePlanResult:
        is_international = airport_country.strip().lower() != origin_country.strip().lower()
        check_in_buffer = _INTERNATIONAL_BUFFER_MIN if is_international else _DOMESTIC_BUFFER_MIN

        directions = await _maps.get_directions(
            origin_lat=user_lat,
            origin_lng=user_lng,
            dest_lat=airport_lat,
            dest_lng=airport_lng,
            mode=transport_mode,
            departure_time=departure_at,
        )

        weather = await _weather.get_weather(
            lat=user_lat,
            lng=user_lng,
            target_time=departure_at,
        )

        if weather.condition in (WeatherCondition.snow, WeatherCondition.storm):
            weather_buffer = 30
        elif weather.condition == WeatherCondition.rain:
            weather_buffer = 15
        else:
            weather_buffer = 0

        total_buffer = check_in_buffer + directions.travel_minutes + weather_buffer
        leave_at = departure_at - timedelta(minutes=total_buffer)

        logger.info(
            "departure_planner.calculated",
            leave_at=leave_at.isoformat(),
            travel_min=directions.travel_minutes,
            checkin_min=check_in_buffer,
            weather_min=weather_buffer,
            mode=transport_mode.value,
        )

        return DeparturePlanResult(
            leave_at=leave_at,
            travel_minutes=directions.travel_minutes,
            distance_km=directions.distance_km,
            check_in_buffer_minutes=check_in_buffer,
            weather_buffer_minutes=weather_buffer,
            weather=weather,
            transport_mode=transport_mode,
            traffic_level=directions.traffic_level,
            flight_departure_at=departure_at,
        )
