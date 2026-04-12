"""Mock flight status service.

Returns deterministic but time-varying flight status based on the
flight number hash and current time relative to departure.
"""

from __future__ import annotations

import hashlib
from datetime import UTC, datetime, timedelta

import structlog

from app.schemas.flight_status import FlightStatusCode, FlightStatusRead

logger = structlog.get_logger(__name__)

_GATE_LETTERS = "ABCDEFG"
_TERMINALS = ["T1", "T2", "T3"]


def _seed_int(flight_number: str) -> int:
    """Deterministic integer derived from flight number."""
    return int(hashlib.md5(flight_number.encode()).hexdigest(), 16)


class MockFlightStatusService:
    """Simulated flight status that transitions through lifecycle phases."""

    async def get_status(
        self,
        carrier_code: str,
        flight_number: str,
        departure_at: datetime,
    ) -> FlightStatusRead:
        now = datetime.now(UTC)
        if departure_at.tzinfo is None:
            dep = departure_at.replace(tzinfo=UTC)
        else:
            dep = departure_at

        seed = _seed_int(flight_number)
        delay_minutes = seed % 46
        gate_letter = _GATE_LETTERS[seed % len(_GATE_LETTERS)]
        gate_number = (seed % 30) + 1
        departure_gate = f"{gate_letter}{gate_number}"
        arrival_gate = f"{_GATE_LETTERS[(seed + 3) % len(_GATE_LETTERS)]}{(seed % 20) + 1}"
        terminal = _TERMINALS[seed % len(_TERMINALS)]
        counter_start = (seed % 50) + 1
        check_in_counter = f"{counter_start}-{counter_start + 3}"

        effective_dep = dep + timedelta(minutes=delay_minutes)
        diff = (now - effective_dep).total_seconds() / 60

        if diff < -180:
            status = FlightStatusCode.scheduled
        elif diff < -90:
            status = FlightStatusCode.check_in_open
        elif diff < -30:
            if delay_minutes > 20:
                status = FlightStatusCode.delayed
            else:
                status = FlightStatusCode.check_in_open
        elif diff < 0:
            status = FlightStatusCode.boarding
        elif diff < 180:
            status = FlightStatusCode.departed
        else:
            status = FlightStatusCode.landed

        logger.info(
            "mock_flight_status.get",
            flight_number=flight_number,
            status=status.value,
            delay=delay_minutes,
        )

        return FlightStatusRead(
            flight_number=flight_number,
            carrier_code=carrier_code,
            departure_gate=departure_gate,
            arrival_gate=arrival_gate,
            terminal=terminal,
            check_in_counter=check_in_counter,
            delay_minutes=delay_minutes,
            status=status,
            updated_at=now,
        )
