"""Google Routes API integration for real road distance, ETA, and polylines."""

from __future__ import annotations

from datetime import UTC, datetime

import httpx
import structlog

from app.core.config import settings
from app.schemas.departure_plan import DirectionsResult, TrafficLevel, TransportMode

logger = structlog.get_logger(__name__)

_ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"
_FIELD_MASK = ",".join(
    [
        "routes.duration",
        "routes.staticDuration",
        "routes.distanceMeters",
        "routes.polyline.encodedPolyline",
    ],
)


class GoogleRoutesService:
    """Thin wrapper around Google Routes API.

    The API key is server-side only. Flutter never receives it; it only receives
    distance, ETA, and the encoded polyline returned by our backend.
    """

    async def get_directions(
        self,
        origin_lat: float,
        origin_lng: float,
        dest_lat: float,
        dest_lng: float,
        mode: TransportMode,
        departure_time: datetime | None = None,
    ) -> DirectionsResult:
        if not settings.GOOGLE_MAPS_SERVER_API_KEY:
            raise RuntimeError("GOOGLE_MAPS_SERVER_API_KEY is not configured")

        travel_mode = _travel_mode(mode)
        body: dict = {
            "origin": {"location": {"latLng": {"latitude": origin_lat, "longitude": origin_lng}}},
            "destination": {
                "location": {"latLng": {"latitude": dest_lat, "longitude": dest_lng}},
            },
            "travelMode": travel_mode,
            "computeAlternativeRoutes": False,
            "polylineQuality": "HIGH_QUALITY",
            "polylineEncoding": "ENCODED_POLYLINE",
            "languageCode": "en",
            "units": "METRIC",
        }

        if travel_mode in {"DRIVE", "TWO_WHEELER"}:
            body["routingPreference"] = "TRAFFIC_AWARE"
            if departure_time is not None:
                body["departureTime"] = _to_rfc3339(departure_time)

        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.post(
                _ROUTES_URL,
                headers={
                    "Content-Type": "application/json",
                    "X-Goog-Api-Key": settings.GOOGLE_MAPS_SERVER_API_KEY,
                    "X-Goog-FieldMask": _FIELD_MASK,
                },
                json=body,
            )
        response.raise_for_status()
        payload = response.json()
        routes = payload.get("routes") or []
        if not routes:
            raise RuntimeError("Google Routes returned no routes")

        route = routes[0]
        travel_seconds = _duration_seconds(route.get("duration"))
        static_seconds = _duration_seconds(route.get("staticDuration")) or travel_seconds
        distance_m = float(route.get("distanceMeters") or 0)
        encoded = ((route.get("polyline") or {}).get("encodedPolyline") or None)

        travel_minutes = max(1, round(travel_seconds / 60))
        distance_km = round(distance_m / 1000, 1)
        traffic = _traffic_level(travel_seconds, static_seconds, travel_mode)

        logger.info(
            "google_routes.get_directions",
            distance_km=distance_km,
            travel_minutes=travel_minutes,
            mode=mode.value,
            traffic=traffic.value,
        )

        return DirectionsResult(
            travel_minutes=travel_minutes,
            distance_km=distance_km,
            mode=mode,
            traffic_level=traffic,
            encoded_polyline=encoded,
            provider="google",
            origin_lat=origin_lat,
            origin_lng=origin_lng,
            destination_lat=dest_lat,
            destination_lng=dest_lng,
        )


def _travel_mode(mode: TransportMode) -> str:
    if mode == TransportMode.walking:
        return "WALK"
    if mode == TransportMode.transit:
        return "TRANSIT"
    # Google Routes has no taxi mode; driving gives the closest user experience.
    return "DRIVE"


def _duration_seconds(value: str | None) -> float:
    if not value:
        return 0
    if value.endswith("s"):
        value = value[:-1]
    try:
        return float(value)
    except ValueError:
        return 0


def _traffic_level(travel_seconds: float, static_seconds: float, travel_mode: str) -> TrafficLevel:
    if travel_mode not in {"DRIVE", "TWO_WHEELER"} or static_seconds <= 0:
        return TrafficLevel.low
    ratio = travel_seconds / static_seconds
    if ratio >= 1.30:
        return TrafficLevel.heavy
    if ratio >= 1.10:
        return TrafficLevel.moderate
    return TrafficLevel.low


def _to_rfc3339(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(UTC).isoformat().replace("+00:00", "Z")
