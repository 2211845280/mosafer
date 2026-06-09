"""Mock flight search service.

Returns realistic but static flight offers filtered by route and shifted
to the requested departure date. Intended as a drop-in stand-in until a
real provider (e.g. Skyscanner, Amadeus) is integrated.
"""

from __future__ import annotations

from datetime import datetime, timedelta
from decimal import Decimal

import structlog

from app.schemas.flights import FlightOfferRead
from app.seed.schedule import mock_departure_datetime, mock_search_date_allowed
from app.services.external.mock_flight_data import MOCK_FLIGHTS
from app.services.external.mock_flight_enrichment import enrich_catalogue_entry
from app.services.flight_identity import dated_provider_flight_id

logger = structlog.get_logger(__name__)


class MockFlightService:
    """In-memory flight search backed by static catalogue data."""

    async def search_flights(
        self,
        origin: str,
        destination: str,
        departure_date: str,
        adults: int = 1,
    ) -> list[FlightOfferRead]:
        """Return mock offers matching *origin* → *destination*.

        ``departure_date`` is ``YYYY-MM-DD``. Every catalogue offer is available
        on each day between 2026-07-15 and 2026-09-30 with a deterministic
        random departure time for that offer + date pair.
        """
        origin_upper = origin.upper()
        dest_upper = destination.upper()
        target_date = datetime.strptime(departure_date, "%Y-%m-%d").date()

        logger.info(
            "mock_flight.search",
            origin=origin_upper,
            destination=dest_upper,
            date=departure_date,
            adults=adults,
        )

        if not mock_search_date_allowed(target_date):
            logger.info("mock_flight.date_out_of_range", date=departure_date)
            return []

        results: list[FlightOfferRead] = []
        for idx, entry in enumerate(MOCK_FLIGHTS):
            if entry["origin_iata"] != origin_upper or entry["destination_iata"] != dest_upper:
                continue

            enriched = enrich_catalogue_entry(entry, slot_hint=idx)
            departure_at = mock_departure_datetime(enriched["offer_id"], target_date)
            arrival_at = departure_at + timedelta(hours=enriched["duration_hours"])
            dated_id = dated_provider_flight_id(
                enriched["provider_flight_id"],
                departure_at,
            )

            results.append(
                FlightOfferRead(
                    offer_id=enriched["offer_id"],
                    provider_flight_id=dated_id,
                    origin_iata=enriched["origin_iata"],
                    destination_iata=enriched["destination_iata"],
                    carrier_code=enriched["carrier_code"],
                    carrier_name=enriched.get("carrier_name"),
                    flight_number=enriched["flight_number"],
                    departure_at=departure_at,
                    arrival_at=arrival_at,
                    total_price=Decimal(enriched["total_price"]),
                    currency=enriched["currency"],
                    cabin_class=enriched.get("cabin_class"),
                    baggage_allowance=enriched.get("baggage_allowance"),
                    departure_terminal=enriched.get("departure_terminal"),
                    source="mock",
                ),
            )

        results.sort(key=lambda o: (o.departure_at, o.total_price or Decimal(0)))

        logger.info("mock_flight.results", count=len(results))
        return results

    async def get_offer_by_id(self, offer_id: str) -> dict | None:
        """Look up a single raw catalogue entry by offer_id."""
        for entry in MOCK_FLIGHTS:
            if entry["offer_id"] == offer_id:
                return entry
        return None
