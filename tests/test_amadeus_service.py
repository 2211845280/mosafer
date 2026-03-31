"""Tests for Amadeus normalization helpers."""

from app.services.amadeus_service import normalize_offers


def test_normalize_offers_maps_core_fields():
    raw = [
        {
            "id": "7",
            "itineraries": [
                {
                    "segments": [
                        {
                            "id": "seg-1",
                            "carrierCode": "MS",
                            "number": "123",
                            "departure": {"iataCode": "CAI", "at": "2026-05-10T10:00:00+00:00"},
                            "arrival": {"iataCode": "DXB", "at": "2026-05-10T14:00:00+00:00"},
                        }
                    ]
                }
            ],
            "price": {"total": "199.99", "currency": "USD"},
        }
    ]
    items = normalize_offers(raw)
    assert len(items) == 1
    item = items[0]
    assert item.offer_id == "7"
    assert item.amadeus_flight_id == "7:seg-1"
    assert item.origin_iata == "CAI"
    assert item.destination_iata == "DXB"
    assert item.carrier_code == "MS"
    assert item.flight_number == "123"
    assert str(item.total_price) == "199.99"
    assert item.currency == "USD"
