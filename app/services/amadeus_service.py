"""Amadeus search service with response normalization."""

from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Any

import httpx

from app.core.config import settings
from app.schemas.flights import AmadeusFlightOfferRead


def _parse_iso_datetime(value: str | None) -> datetime:
    if value is None:
        raise ValueError("Missing datetime in Amadeus response")
    normalized = value.replace("Z", "+00:00")
    return datetime.fromisoformat(normalized)


def _to_decimal(value: str | None) -> Decimal | None:
    if value is None:
        return None
    try:
        return Decimal(value)
    except (InvalidOperation, ValueError):
        return None


def normalize_offers(raw_offers: list[dict[str, Any]]) -> list[AmadeusFlightOfferRead]:
    """Normalize raw Amadeus offers into API schema."""
    items: list[AmadeusFlightOfferRead] = []
    for offer in raw_offers:
        itineraries = offer.get("itineraries") or []
        if not itineraries:
            continue
        first = itineraries[0]
        segments = first.get("segments") or []
        if not segments:
            continue
        first_seg = segments[0]
        last_seg = segments[-1]
        price = offer.get("price") or {}
        offer_id = str(offer.get("id", ""))
        provider_id = f"{offer_id}:{first_seg.get('id', '')}".strip(":")
        items.append(
            AmadeusFlightOfferRead(
                offer_id=offer_id,
                amadeus_flight_id=provider_id,
                origin_iata=(first_seg.get("departure") or {}).get("iataCode", "").upper(),
                destination_iata=(last_seg.get("arrival") or {}).get("iataCode", "").upper(),
                carrier_code=str(first_seg.get("carrierCode", "")).upper(),
                flight_number=str(first_seg.get("number", "")),
                departure_at=_parse_iso_datetime((first_seg.get("departure") or {}).get("at")),
                arrival_at=_parse_iso_datetime((last_seg.get("arrival") or {}).get("at")),
                total_price=_to_decimal(price.get("total")),
                currency=price.get("currency"),
            ),
        )
    return items


class AmadeusService:
    """Simple token + flight offers client."""

    async def _get_access_token(self) -> str | None:
        if not settings.AMADEUS_CLIENT_ID or not settings.AMADEUS_CLIENT_SECRET:
            return None
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.post(
                f"{settings.AMADEUS_BASE_URL}/v1/security/oauth2/token",
                data={
                    "grant_type": "client_credentials",
                    "client_id": settings.AMADEUS_CLIENT_ID,
                    "client_secret": settings.AMADEUS_CLIENT_SECRET,
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            response.raise_for_status()
            payload = response.json()
            return payload.get("access_token")

    async def search_flights(
        self,
        *,
        origin_iata: str,
        destination_iata: str,
        departure_date: str,
        adults: int = 1,
        limit: int = 20,
    ) -> list[AmadeusFlightOfferRead]:
        """Fetch and normalize offers from Amadeus. Returns empty when disabled."""
        token = await self._get_access_token()
        if not token:
            return []
        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                f"{settings.AMADEUS_BASE_URL}/v2/shopping/flight-offers",
                params={
                    "originLocationCode": origin_iata.upper(),
                    "destinationLocationCode": destination_iata.upper(),
                    "departureDate": departure_date,
                    "adults": adults,
                    "max": limit,
                },
                headers={"Authorization": f"Bearer {token}"},
            )
            response.raise_for_status()
            payload = response.json()
            return normalize_offers(payload.get("data", []))
