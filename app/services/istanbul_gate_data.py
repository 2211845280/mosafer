"""Canonical IST departure gates for demo / mock flight status.

Gates must exist on the curated indoor fallback map (level 1) and align
with OpenLevelUp-style G-concourse labels at Istanbul Airport.
"""

from __future__ import annotations

import hashlib

# Gates drawn in istanbul_indoor_fallback (level 1 departures).
IST_DEMO_GATES: tuple[str, ...] = (
    "G1",
    "G2",
    "G3",
    "G4",
    "G5",
    "G6",
    "G7",
    "G8",
    "G12",
)

# Primary review trip (IST → LHR) always uses G12 for indoor-map demo.
_IST_FLIGHT_GATE_OVERRIDES: dict[str, str] = {
    "TK0244": "G12",
}

IST_DEPARTURES_LEVEL = "1"
IST_MAIN_TERMINAL = "Main Terminal"


def _seed_int(flight_number: str) -> int:
    return int(hashlib.md5(flight_number.strip().upper().encode()).hexdigest(), 16)


def gate_for_ist_flight(flight_number: str) -> str:
    """Deterministic IST gate from flight number; only returns allowed demo gates."""
    normalized = flight_number.strip().upper()
    override = _IST_FLIGHT_GATE_OVERRIDES.get(normalized)
    if override is not None:
        return override
    idx = _seed_int(normalized) % len(IST_DEMO_GATES)
    return IST_DEMO_GATES[idx]


def is_valid_ist_demo_gate(gate: str | None) -> bool:
    if not gate:
        return False
    return gate.strip().upper() in IST_DEMO_GATES


def level_for_ist_gate(_gate: str | None = None) -> str:
    """All demo IST gates are on departures level in fallback / OpenLevelUp."""
    return IST_DEPARTURES_LEVEL
