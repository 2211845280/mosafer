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
from app.services.external.mock_flight_data import MOCK_FLIGHTS

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

        ``departure_date`` is ``YYYY-MM-DD``. The catalogue times-of-day are
        preserved but the date component is shifted to the requested day.
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

        results: list[FlightOfferRead] = []
        for entry in MOCK_FLIGHTS:
            if entry["origin_iata"] != origin_upper or entry["destination_iata"] != dest_upper:
                continue

            dep_h, dep_m = (int(p) for p in entry["departure_time"].split(":"))
            departure_at = datetime(
                target_date.year,
                target_date.month,
                target_date.day,
                dep_h,
                dep_m,
            )
            arrival_at = departure_at + timedelta(hours=entry["duration_hours"])

            results.append(
                FlightOfferRead(
                    offer_id=entry["offer_id"],
                    provider_flight_id=entry["provider_flight_id"],
                    origin_iata=entry["origin_iata"],
                    destination_iata=entry["destination_iata"],
                    carrier_code=entry["carrier_code"],
                    flight_number=entry["flight_number"],
                    departure_at=departure_at,
                    arrival_at=arrival_at,
                    total_price=Decimal(entry["total_price"]),
                    currency=entry["currency"],
                    source="mock",
                ),
            )

        results.sort(key=lambda o: o.total_price or Decimal(0))

        logger.info("mock_flight.results", count=len(results))
        return results

    async def get_offer_by_id(self, offer_id: str) -> dict | None:
        """Look up a single raw catalogue entry by offer_id."""
        for entry in MOCK_FLIGHTS:
            if entry["offer_id"] == offer_id:
                return entry
        return None
