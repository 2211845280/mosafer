"""Integration tests for checkout session booking flow."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest


def _checkout_payload(*, provider_flight_id: str, departure_at: datetime, seat: str) -> dict:
    arrival_at = departure_at + timedelta(hours=3, minutes=30)
    return {
        "provider_flight_id": provider_flight_id,
        "origin_iata": "AMM",
        "destination_iata": "IST",
        "carrier_code": "TK",
        "flight_number": "TK816",
        "departure_at": departure_at.isoformat(),
        "arrival_at": arrival_at.isoformat(),
        "base_price": "210.00",
        "currency": "USD",
        "seat": seat,
        "seats": [seat],
        "adults": 1,
        "total_price": "210.00",
    }


def _passenger_payload(seat: str) -> dict:
    return {
        "passengers": [
            {
                "title": "MR",
                "given_name": "TEST",
                "family_name": "TRAVELER",
                "date_of_birth": "1990-01-01",
                "gender": "M",
                "nationality": "LY",
                "passport_number": f"P{uuid.uuid4().hex[:8].upper()}",
                "passport_expiry": (date.today() + timedelta(days=365)).isoformat(),
                "passport_issuing_country": "LY",
                "seat": seat,
            },
        ],
    }


@pytest.mark.asyncio
async def test_checkout_session_creates_paid_reservation_on_payment(
    prepare_schema,
    client,
    authed_user,
    seeded_flight,
):
    _, headers = authed_user
    seat = f"{(uuid.uuid4().int % 80) + 1}A"
    session_response = await client.post(
        "/api/v1/checkout-sessions",
        json={
            "provider_flight_id": seeded_flight.provider_flight_id,
            "origin_iata": seeded_flight.origin_iata,
            "destination_iata": seeded_flight.destination_iata,
            "carrier_code": seeded_flight.carrier_code,
            "flight_number": seeded_flight.flight_number,
            "departure_at": seeded_flight.departure_at.isoformat(),
            "arrival_at": seeded_flight.arrival_at.isoformat(),
            "base_price": "120.00",
            "currency": "USD",
            "seat": seat,
            "seats": [seat],
            "adults": 1,
            "total_price": "140.00",
        },
        headers=headers,
    )
    assert session_response.status_code == 201
    session_body = session_response.json()
    session_id = session_body["id"]

    passengers_response = await client.post(
        f"/api/v1/checkout-sessions/{session_id}/passenger-details",
        json=_passenger_payload(seat),
        headers=headers,
    )
    assert passengers_response.status_code == 200

    payment_response = await client.post(
        "/api/v1/payments/create-session",
        json={"checkout_session_id": session_id, "locale": "en"},
        headers=headers,
    )
    assert payment_response.status_code == 201
    payment_body = payment_response.json()
    payment_lookup = await client.get(
        f"/api/v1/payments/{payment_body['payment_id']}",
        headers=headers,
    )
    assert payment_lookup.status_code == 200
    provider_payment_id = payment_lookup.json()["provider_payment_id"]

    webhook_response = await client.post(
        "/api/v1/payments/webhook",
        json={
            "provider_payment_id": provider_payment_id,
            "status": "completed",
            "signature": "mock-signature",
        },
    )
    assert webhook_response.status_code == 200

    payment_status = await client.get(
        f"/api/v1/payments/{payment_body['payment_id']}",
        headers=headers,
    )
    assert payment_status.status_code == 200
    payment_json = payment_status.json()
    assert payment_json["status"] == "completed"
    assert payment_json["reservation_id"] is not None

    reservation_response = await client.get(
        f"/api/v1/reservations/{payment_json['reservation_id']}",
        headers=headers,
    )
    assert reservation_response.status_code == 200
    reservation_json = reservation_response.json()
    assert reservation_json["status"] == "paid"
    assert reservation_json["ticket_number"]


@pytest.mark.asyncio
async def test_same_route_different_dates_get_distinct_flights(
    prepare_schema,
    client,
    authed_user,
):
    """Legacy undated provider_flight_id must not reuse a flight from another day."""
    _, headers = authed_user
    legacy_id = "TK-AMM-IST-0800"
    first_departure = datetime(2026, 6, 6, 8, 0, tzinfo=UTC)
    second_departure = datetime(2026, 6, 20, 8, 0, tzinfo=UTC)

    first_response = await client.post(
        "/api/v1/checkout-sessions",
        json=_checkout_payload(
            provider_flight_id=legacy_id,
            departure_at=first_departure,
            seat="12A",
        ),
        headers=headers,
    )
    assert first_response.status_code == 201
    first_body = first_response.json()

    second_response = await client.post(
        "/api/v1/checkout-sessions",
        json=_checkout_payload(
            provider_flight_id=legacy_id,
            departure_at=second_departure,
            seat="14B",
        ),
        headers=headers,
    )
    assert second_response.status_code == 201
    second_body = second_response.json()

    assert first_body["flight_id"] != second_body["flight_id"]
    assert first_body["flight"]["departure_at"].startswith("2026-06-06")
    assert second_body["flight"]["departure_at"].startswith("2026-06-20")
    assert first_body["flight"]["provider_flight_id"].endswith("#2026-06-06")
    assert second_body["flight"]["provider_flight_id"].endswith("#2026-06-20")


@pytest.mark.asyncio
async def test_mock_search_returns_dated_provider_flight_id(prepare_schema, client, authed_user):
    _, headers = authed_user
    expected_date = "2026-08-01"
    response = await client.get(
        "/api/v1/flights/search",
        params={
            "origin_iata": "AMM",
            "destination_iata": "IST",
            "departure_date": expected_date,
            "adults": 1,
        },
        headers=headers,
    )
    assert response.status_code == 200
    offers = response.json()
    assert isinstance(offers, list)
    assert len(offers) > 0
    assert all(f"#{expected_date}" in offer["provider_flight_id"] for offer in offers)
    assert offers[0]["departure_at"].startswith(expected_date)


@pytest.mark.asyncio
async def test_mock_search_ist_lhr_demo_date(prepare_schema, client, authed_user):
    """IST→LHR on a demo-window date returns paginated offers (web search scenario)."""
    _, headers = authed_user
    response = await client.get(
        "/api/v1/flights/search",
        params={
            "origin_iata": "IST",
            "destination_iata": "LHR",
            "departure_date": "2026-07-15",
            "adults": 1,
        },
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total"] >= 1
    assert len(body["items"]) >= 1
    assert body["items"][0]["origin_iata"] == "IST"
    assert body["items"][0]["destination_iata"] == "LHR"


@pytest.mark.asyncio
async def test_mock_search_empty_outside_demo_window(prepare_schema, client, authed_user):
    _, headers = authed_user
    response = await client.get(
        "/api/v1/flights/search",
        params={
            "origin_iata": "IST",
            "destination_iata": "LHR",
            "departure_date": "2026-06-01",
            "adults": 1,
        },
        headers=headers,
    )
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_mock_search_same_route_different_days(prepare_schema, client, authed_user):
    _, headers = authed_user
    params_base = {
        "origin_iata": "IST",
        "destination_iata": "LHR",
        "adults": 1,
    }
    first = await client.get(
        "/api/v1/flights/search",
        params={**params_base, "departure_date": "2026-07-20"},
        headers=headers,
    )
    second = await client.get(
        "/api/v1/flights/search",
        params={**params_base, "departure_date": "2026-08-20"},
        headers=headers,
    )
    assert first.status_code == 200
    assert second.status_code == 200
    first_offers = first.json()
    second_offers = second.json()
    assert len(first_offers) > 0
    assert len(second_offers) > 0
    assert first_offers[0]["departure_at"] != second_offers[0]["departure_at"]
