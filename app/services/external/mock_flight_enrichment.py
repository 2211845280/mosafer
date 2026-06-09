"""Enrich mock catalogue entries with airline display metadata."""

from __future__ import annotations

from app.data.airlines import CABIN_CLASSES, carrier_name

# Deterministic cabin / baggage by slot index
_BAGGAGE = ("23 kg", "30 kg", "2 × 23 kg")
_CHECKIN = ("T3", "T1", "T2", "Main")


def enrich_catalogue_entry(entry: dict, *, slot_hint: int = 0) -> dict:
    """Return a copy of *entry* with carrier_name, cabin, baggage, terminal."""
    out = dict(entry)
    code = str(entry["carrier_code"]).upper()
    out["carrier_name"] = carrier_name(code)
    out["cabin_class"] = "Economy" if slot_hint % 6 != 0 else CABIN_CLASSES[2]
    out["baggage_allowance"] = _BAGGAGE[slot_hint % len(_BAGGAGE)]
    out["departure_terminal"] = _CHECKIN[slot_hint % len(_CHECKIN)]
    return out
