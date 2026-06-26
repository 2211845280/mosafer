"""Unit tests for mock flight search catalogue."""

from __future__ import annotations

import pytest

from app.services.external.mock_flight_data import MOCK_FLIGHTS
from app.services.external.mock_flight_service import MockFlightService


@pytest.mark.asyncio
async def test_ist_lhr_search_returns_offers() -> None:
    service = MockFlightService()
    offers = await service.search_flights(
        origin="IST",
        destination="LHR",
        departure_date="2026-07-15",
        adults=1,
    )
    assert len(offers) >= 1
    assert all(o.origin_iata == "IST" and o.destination_iata == "LHR" for o in offers)


def test_mock_catalogue_includes_ist_lhr() -> None:
    ist_lhr = [
        f for f in MOCK_FLIGHTS if f["origin_iata"] == "IST" and f["destination_iata"] == "LHR"
    ]
    assert len(ist_lhr) >= 10
