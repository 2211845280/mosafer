"""Google Directions API (legacy REST) for road-following map polylines."""

from __future__ import annotations

from dataclasses import dataclass

import httpx
import structlog

from app.core.config import settings
from app.schemas.departure_plan import TransportMode

logger = structlog.get_logger(__name__)

_DIRECTIONS_URL = "https://maps.googleapis.com/maps/api/directions/json"


@dataclass(frozen=True)
class MapRouteOption:
    encoded_polyline: str
    distance_km: float
    travel_minutes: int
    provider: str
    route_index: int
    summary: str | None = None


@dataclass(frozen=True)
class MapDirectionsResult:
    encoded_polyline: str
    distance_km: float
    travel_minutes: int
    provider: str = "google_directions_backend"
    routes: tuple[MapRouteOption, ...] = ()


class GoogleDirectionsBackendService:
    """Server-side wrapper around Google Directions JSON API."""

    async def get_directions(
        self,
        origin_lat: float,
        origin_lng: float,
        dest_lat: float,
        dest_lng: float,
        mode: TransportMode = TransportMode.driving,
    ) -> MapDirectionsResult:
        api_key = settings.GOOGLE_MAPS_API_KEY or settings.GOOGLE_MAPS_SERVER_API_KEY
        if not api_key:
            raise RuntimeError("GOOGLE_MAPS_API_KEY is not configured")

        params = {
            "origin": f"{origin_lat},{origin_lng}",
            "destination": f"{dest_lat},{dest_lng}",
            "mode": _travel_mode(mode),
            "alternatives": "true",
            "key": api_key,
        }

        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(_DIRECTIONS_URL, params=params)

        response.raise_for_status()
        payload = response.json()

        status = (payload.get("status") or "UNKNOWN").upper()
        if status != "OK":
            error_message = payload.get("error_message") or "Directions request failed"
            logger.warning(
                "google_directions_backend.failed",
                status=status,
                error=error_message,
            )
            raise RuntimeError(f"Google Directions API error: {status} — {error_message}")

        raw_routes = payload.get("routes") or []
        if not raw_routes:
            raise RuntimeError("Google Directions API returned no routes")

        parsed_routes: list[MapRouteOption] = []
        for index, route in enumerate(raw_routes):
            option = _parse_route(route, index)
            if option is not None:
                parsed_routes.append(option)

        if not parsed_routes:
            raise RuntimeError("Google Directions API returned no valid overview polylines")

        primary = parsed_routes[0]

        logger.info(
            "google_directions_backend.success",
            distance_km=primary.distance_km,
            travel_minutes=primary.travel_minutes,
            polyline_length=len(primary.encoded_polyline),
            mode=mode.value,
            route_count=len(parsed_routes),
        )

        return MapDirectionsResult(
            encoded_polyline=primary.encoded_polyline,
            distance_km=primary.distance_km,
            travel_minutes=primary.travel_minutes,
            provider="google_directions_backend",
            routes=tuple(parsed_routes),
        )


def _parse_route(route: dict, index: int) -> MapRouteOption | None:
    encoded = ((route.get("overview_polyline") or {}).get("points") or "").strip()
    if not encoded:
        return None

    legs = route.get("legs") or []
    distance_meters = 0
    duration_seconds = 0
    for leg in legs:
        distance_meters += int(((leg.get("distance") or {}).get("value")) or 0)
        duration_seconds += int(((leg.get("duration") or {}).get("value")) or 0)

    summary = (route.get("summary") or "").strip() or None

    return MapRouteOption(
        encoded_polyline=encoded,
        distance_km=round(distance_meters / 1000, 1),
        travel_minutes=max(1, round(duration_seconds / 60)),
        provider="google_directions_backend",
        route_index=index,
        summary=summary,
    )


def _travel_mode(mode: TransportMode) -> str:
    if mode == TransportMode.walking:
        return "walking"
    if mode == TransportMode.transit:
        return "transit"
    return "driving"
