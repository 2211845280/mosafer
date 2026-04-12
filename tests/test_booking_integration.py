"""Integration tests for reservation booking flow."""

from __future__ import annotations

import uuid

import pytest


@pytest.mark.asyncio
async def test_create_reservation_success(prepare_schema, client, authed_user, seeded_flight):
    _, headers = authed_user
    payload = {
        "provider_flight_id": seeded_flight.provider_flight_id,
        "origin_iata": seeded_flight.origin_iata,
        "destination_iata": seeded_flight.destination_iata,
        "carrier_code": seeded_flight.carrier_code,
        "flight_number": seeded_flight.flight_number,
        "departure_at": seeded_flight.departure_at.isoformat(),
        "arrival_at": seeded_flight.arrival_at.isoformat(),
        "base_price": "120.00",
        "currency": "USD",
        "seat": f"{(uuid.uuid4().int % 80) + 1}A",
        "total_price": "140.00",
    }
    response = await client.post("/api/v1/reservations", json=payload, headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body["seat"] == payload["seat"].strip().upper()
    assert body["status"] == "booked"
