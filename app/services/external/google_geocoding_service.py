"""Google Geocoding API wrapper for address → coordinates lookup."""

from __future__ import annotations

from dataclasses import dataclass

import httpx
import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)

_GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"


@dataclass(frozen=True)
class GeocodeResult:
    formatted_address: str
    lat: float
    lng: float


class GoogleGeocodingService:
    async def geocode(self, address: str) -> GeocodeResult:
        query = address.strip()
        if not query:
            raise ValueError("Address is required")

        api_key = settings.GOOGLE_MAPS_API_KEY or settings.GOOGLE_MAPS_SERVER_API_KEY
        if not api_key:
            raise RuntimeError("GOOGLE_MAPS_API_KEY is not configured")

        params = {"address": query, "key": api_key}

        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(_GEOCODE_URL, params=params)

        response.raise_for_status()
        payload = response.json()

        status = (payload.get("status") or "UNKNOWN").upper()
        if status != "OK":
            error_message = payload.get("error_message") or "Geocoding request failed"
            logger.warning(
                "google_geocoding.failed",
                status=status,
                error=error_message,
            )
            raise RuntimeError(f"Google Geocoding API error: {status} — {error_message}")

        results = payload.get("results") or []
        if not results:
            raise RuntimeError("No results found for this address")

        first = results[0]
        location = first.get("geometry", {}).get("location") or {}
        lat = location.get("lat")
        lng = location.get("lng")
        if lat is None or lng is None:
            raise RuntimeError("Geocoding result missing coordinates")

        formatted = first.get("formatted_address") or query
        return GeocodeResult(formatted_address=formatted, lat=float(lat), lng=float(lng))
