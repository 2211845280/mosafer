"""Generate booking references and e-ticket numbers."""

from __future__ import annotations

import random
import string

from app.data.airlines import carrier_numeric


def generate_pnr() -> str:
    """6-character alphanumeric PNR (excludes I, O, 0, 1 for readability)."""
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return "".join(random.choices(alphabet, k=6))


def generate_eticket_number(carrier_code: str) -> str:
    """Airline numeric prefix + 10-digit document number (IATA-style)."""
    prefix = carrier_numeric(carrier_code)
    suffix = "".join(random.choices(string.digits, k=10))
    return f"{prefix}-{suffix}"
