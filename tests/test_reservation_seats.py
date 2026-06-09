"""Tests for multi-seat reservation logic."""

from __future__ import annotations

import pytest

from app.schemas.reservations import ReservationCreate


def test_reservation_create_normalizes_single_seat():
    data = ReservationCreate(
        provider_flight_id="TK130",
        origin_iata="IST",
        destination_iata="LHR",
        carrier_code="TK",
        flight_number="130",
        departure_at="2026-06-07T08:00:00+00:00",
        arrival_at="2026-06-07T12:30:00+00:00",
        seat="12A",
        adults=1,
    )
    assert data.seats == ["12A"]
    assert data.seat == "12A"


def test_reservation_create_requires_matching_adult_count():
    with pytest.raises(ValueError, match="Expected 2 seat"):
        ReservationCreate(
            provider_flight_id="TK130",
            origin_iata="IST",
            destination_iata="LHR",
            carrier_code="TK",
            flight_number="130",
            departure_at="2026-06-07T08:00:00+00:00",
            arrival_at="2026-06-07T12:30:00+00:00",
            seats=["12A"],
            adults=2,
        )


def test_reservation_create_accepts_multiple_seats():
    data = ReservationCreate(
        provider_flight_id="TK130",
        origin_iata="IST",
        destination_iata="LHR",
        carrier_code="TK",
        flight_number="130",
        departure_at="2026-06-07T08:00:00+00:00",
        arrival_at="2026-06-07T12:30:00+00:00",
        seats=["12A", "14B"],
        adults=2,
    )
    assert data.seats == ["12A", "14B"]
    assert data.seat == "12A"
