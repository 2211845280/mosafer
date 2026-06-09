"""Tests for IST gate assignment and indoor map alignment."""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta

import pytest

from app.services.external.mock_flight_status_service import MockFlightStatusService
from app.services.istanbul_gate_data import (
    IST_DEMO_GATES,
    gate_for_ist_flight,
    is_valid_ist_demo_gate,
)
from app.services.istanbul_indoor_fallback import build_istanbul_indoor_map


@pytest.mark.parametrize("flight_number", ["TK0244", "TK690", "TK001", "TK812"])
def test_gate_for_ist_flight_returns_allowed_gate(flight_number: str) -> None:
    gate = gate_for_ist_flight(flight_number)
    assert is_valid_ist_demo_gate(gate)
    assert gate in IST_DEMO_GATES


def test_tk0244_override_is_g12() -> None:
    assert gate_for_ist_flight("TK0244") == "G12"
    assert gate_for_ist_flight("tk0244") == "G12"


def test_istanbul_fallback_contains_all_demo_gates() -> None:
    data = build_istanbul_indoor_map()
    gate_labels = {f.label for f in data.features if f.type == "gate"}
    for gate in IST_DEMO_GATES:
        assert gate in gate_labels


def test_istanbul_fallback_highlight_gate() -> None:
    data = build_istanbul_indoor_map(highlight_gate="G12")
    assert data.highlight_gate == "G12"
    assert any(f.label == "G12" for f in data.features)


@pytest.mark.asyncio
async def test_mock_status_ist_uses_demo_gates() -> None:
    service = MockFlightStatusService()
    status = await service.get_status(
        carrier_code="TK",
        flight_number="TK760",
        departure_at=datetime.now(UTC) + timedelta(days=2),
        origin_iata="IST",
    )
    assert is_valid_ist_demo_gate(status.departure_gate)
    assert status.terminal == "Main Terminal"


@pytest.mark.asyncio
async def test_mock_status_non_ist_unchanged_pattern() -> None:
    service = MockFlightStatusService()
    status = await service.get_status(
        carrier_code="MS",
        flight_number="MS100",
        departure_at=datetime.now(UTC) + timedelta(days=2),
        origin_iata="MJI",
    )
    assert status.departure_gate is not None
    assert status.departure_gate[0] in "ABCDEFG"


def test_gate_for_ist_flight_is_deterministic() -> None:
    assert gate_for_ist_flight("TK690") == gate_for_ist_flight("TK690")


if __name__ == "__main__":
    asyncio.run(test_mock_status_ist_uses_demo_gates())
