"""Road directions proxy for Flutter map polylines (avoids browser CORS)."""

from __future__ import annotations

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.core.rbac import require_permission
from app.schemas.departure_plan import TransportMode
from app.services.external.google_geocoding_service import GoogleGeocodingService
from app.services.external.google_directions_service import (
    GoogleDirectionsBackendService,
    MapDirectionsResult,
    MapRouteOption,
)
from app.services.external.google_routes_service import GoogleRoutesService

logger = structlog.get_logger(__name__)

router = APIRouter()

_google_directions = GoogleDirectionsBackendService()
_google_routes = GoogleRoutesService()
_google_geocoding = GoogleGeocodingService()


def _route_option_payload(option: MapRouteOption) -> dict:
    return {
        "encoded_polyline": option.encoded_polyline,
        "distance_km": option.distance_km,
        "travel_minutes": option.travel_minutes,
        "provider": option.provider,
        "route_index": option.route_index,
        "summary": option.summary,
    }


def _directions_response(result: MapDirectionsResult) -> dict:
    routes = (
        [_route_option_payload(option) for option in result.routes]
        if result.routes
        else [
            {
                "encoded_polyline": result.encoded_polyline,
                "distance_km": result.distance_km,
                "travel_minutes": result.travel_minutes,
                "provider": result.provider,
                "route_index": 0,
                "summary": None,
            }
        ]
    )

    return {
        "encoded_polyline": result.encoded_polyline,
        "distance_km": result.distance_km,
        "travel_minutes": result.travel_minutes,
        "provider": result.provider,
        "routes": routes,
    }


@router.get(
    "/maps/directions",
    dependencies=[Depends(require_permission("flights.read"))],
)
async def get_map_directions(
    origin_lat: float = Query(..., ge=-90, le=90),
    origin_lng: float = Query(..., ge=-180, le=180),
    dest_lat: float = Query(..., ge=-90, le=90),
    dest_lng: float = Query(..., ge=-180, le=180),
    mode: TransportMode = Query(TransportMode.driving),
) -> dict:
    """Return a road-following encoded polyline between two coordinates."""
    errors: list[str] = []

    try:
        result = await _google_directions.get_directions(
            origin_lat=origin_lat,
            origin_lng=origin_lng,
            dest_lat=dest_lat,
            dest_lng=dest_lng,
            mode=mode,
        )
        return _directions_response(result)
    except Exception as exc:
        errors.append(f"directions: {exc}")
        logger.warning("maps.directions.directions_failed", error=str(exc))

    try:
        routes_result = await _google_routes.get_directions(
            origin_lat=origin_lat,
            origin_lng=origin_lng,
            dest_lat=dest_lat,
            dest_lng=dest_lng,
            mode=mode,
        )
        if routes_result.encoded_polyline:
            return {
                "encoded_polyline": routes_result.encoded_polyline,
                "distance_km": routes_result.distance_km,
                "travel_minutes": routes_result.travel_minutes,
                "provider": routes_result.provider,
                "routes": [
                    {
                        "encoded_polyline": routes_result.encoded_polyline,
                        "distance_km": routes_result.distance_km,
                        "travel_minutes": routes_result.travel_minutes,
                        "provider": routes_result.provider,
                        "route_index": 0,
                        "summary": None,
                    }
                ],
            }
        errors.append("routes: empty encoded_polyline")
    except Exception as exc:
        errors.append(f"routes: {exc}")
        logger.warning("maps.directions.routes_failed", error=str(exc))

    raise HTTPException(
        status_code=status.HTTP_502_BAD_GATEWAY,
        detail={
            "message": "Unable to compute road-following directions",
            "errors": errors,
        },
    )


@router.get(
    "/maps/geocode",
    dependencies=[Depends(require_permission("flights.read"))],
)
async def geocode_address(
    address: str = Query(..., min_length=3, max_length=500),
) -> dict:
    """Resolve a free-text address to coordinates."""
    try:
        result = await _google_geocoding.geocode(address)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc

    return {
        "formatted_address": result.formatted_address,
        "lat": result.lat,
        "lng": result.lng,
    }

