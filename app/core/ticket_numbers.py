"""Ticket number normalization helpers."""

from __future__ import annotations

import re


def ticket_number_candidates(value: str) -> list[str]:
    """Return unique lookup candidates for a ticket number (raw + compact)."""
    raw = value.strip().upper()
    if not raw:
        return []
    compact = re.sub(r"[^A-Z0-9]", "", raw)
    candidates: list[str] = []
    for candidate in (raw, compact):
        if candidate and candidate not in candidates:
            candidates.append(candidate)
    return candidates


def compact_ticket_number(value: str) -> str:
    return re.sub(r"[^A-Z0-9]", "", value.strip().upper())
