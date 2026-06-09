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
from app.core.config import settings
from app.services.external.google_routes_service import GoogleRoutesService
from app.services.external.mock_maps_service import MockMapsService
from app.services.external.openweather_service import get_destination_weather

logger = structlog.get_logger(__name__)

_mock_maps = MockMapsService()
_google_routes = GoogleRoutesService()

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
        *,
        destination_airport_lat: float | None = None,
        destination_airport_lng: float | None = None,
        arrival_at: datetime | None = None,
    ) -> DeparturePlanResult:
        is_international = airport_country.strip().lower() != origin_country.strip().lower()
        check_in_buffer = _INTERNATIONAL_BUFFER_MIN if is_international else _DOMESTIC_BUFFER_MIN

        directions = await self._directions(
            user_lat=user_lat,
            user_lng=user_lng,
            airport_lat=airport_lat,
            airport_lng=airport_lng,
            transport_mode=transport_mode,
            departure_at=departure_at,
        )

        weather = await get_destination_weather(
            lat=airport_lat,
            lng=airport_lng,
            target_time=departure_at,
        )

        destination_weather = None
        if (
            destination_airport_lat is not None
            and destination_airport_lng is not None
            and arrival_at is not None
        ):
            destination_weather = await get_destination_weather(
                lat=destination_airport_lat,
                lng=destination_airport_lng,
                target_time=arrival_at,
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
            destination_weather=destination_weather,
            transport_mode=transport_mode,
            traffic_level=directions.traffic_level,
            flight_departure_at=departure_at,
            encoded_polyline=directions.encoded_polyline,
            route_provider=directions.provider,
            origin_lat=user_lat,
            origin_lng=user_lng,
            airport_lat=airport_lat,
            airport_lng=airport_lng,
        )

    async def _directions(
        self,
        *,
        user_lat: float,
        user_lng: float,
        airport_lat: float,
        airport_lng: float,
        transport_mode: TransportMode,
        departure_at: datetime,
    ):
        if settings.GOOGLE_ROUTES_ENABLED and settings.GOOGLE_MAPS_SERVER_API_KEY:
            try:
                return await _google_routes.get_directions(
                    origin_lat=user_lat,
                    origin_lng=user_lng,
                    dest_lat=airport_lat,
                    dest_lng=airport_lng,
                    mode=transport_mode,
                    departure_time=departure_at,
                )
            except Exception as exc:  # pragma: no cover - external provider fallback
                logger.warning(
                    "departure_planner.google_routes_fallback",
                    error=str(exc),
                    mode=transport_mode.value,
                )

        return await _mock_maps.get_directions(
            origin_lat=user_lat,
            origin_lng=user_lng,
            dest_lat=airport_lat,
            dest_lng=airport_lng,
            mode=transport_mode,
            departure_time=departure_at,
        )
