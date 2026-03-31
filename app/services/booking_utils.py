"""Helpers for seat validation and capacity checks."""

import re

_SEAT_PATTERN = re.compile(r"^[1-9][0-9]?[A-F]$")


def is_valid_seat(seat: str) -> bool:
    """Validate seat label e.g. 12A (row 1-99, letter A-F)."""
    return bool(_SEAT_PATTERN.match(seat.strip().upper()))


def normalize_seat(seat: str) -> str:
    return seat.strip().upper()
