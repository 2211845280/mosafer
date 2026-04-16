"""Mock Google Maps Directions service.

Returns deterministic travel time estimates based on haversine distance,
transport mode, and simulated traffic conditions.
"""

from __future__ import annotations

import math
from datetime import datetime

import structlog

from app.schemas.departure_plan import DirectionsResult, TrafficLevel, TransportMode

logger = structlog.get_logger(__name__)

_EARTH_RADIUS_KM = 6371.0
_ROAD_FACTOR = 1.3

_SPEED_KMH: dict[TransportMode, float] = {
    TransportMode.driving: 60.0,
    TransportMode.transit: 40.0,
    TransportMode.walking: 5.0,
    TransportMode.taxi: 55.0,
}


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Return straight-line distance in km between two coordinates."""
    rlat1, rlng1, rlat2, rlng2 = (math.radians(v) for v in (lat1, lng1, lat2, lng2))
    dlat = rlat2 - rlat1
    dlng = rlng2 - rlng1
    a = math.sin(dlat / 2) ** 2 + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlng / 2) ** 2
    return 2 * _EARTH_RADIUS_KM * math.asin(math.sqrt(a))


def _traffic_multiplier(hour: int, mode: TransportMode) -> tuple[float, TrafficLevel]:
    """Return (multiplier, level) for the given local hour and mode."""
    if mode in (TransportMode.walking, TransportMode.transit):
        return 1.0, TrafficLevel.low

    if 7 <= hour <= 9 or 17 <= hour <= 19:
        return 1.35, TrafficLevel.heavy
    if 10 <= hour <= 16:
        return 1.15, TrafficLevel.moderate
    return 1.0, TrafficLevel.low


class MockMapsService:
    """Simulated directions service using haversine + mode-based speed."""

    async def get_directions(
        self,
        origin_lat: float,
        origin_lng: float,
        dest_lat: float,
        dest_lng: float,
        mode: TransportMode,
        departure_time: datetime | None = None,
    ) -> DirectionsResult:
        straight_km = _haversine(origin_lat, origin_lng, dest_lat, dest_lng)
        road_km = round(straight_km * _ROAD_FACTOR, 1)

        hour = departure_time.hour if departure_time else 12
        multiplier, traffic_level = _traffic_multiplier(hour, mode)

        speed = _SPEED_KMH.get(mode, 50.0)
        raw_minutes = (road_km / speed) * 60
        travel_minutes = max(1, round(raw_minutes * multiplier))

        logger.info(
            "mock_maps.get_directions",
            distance_km=road_km,
            travel_minutes=travel_minutes,
            mode=mode.value,
            traffic=traffic_level.value,
        )

        return DirectionsResult(
            travel_minutes=travel_minutes,
            distance_km=road_km,
            mode=mode,
            traffic_level=traffic_level,
        )
