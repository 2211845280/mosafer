"""Deterministic random departure schedule for demo seed data."""

from __future__ import annotations

import random
import zlib
from datetime import UTC, date, datetime, timedelta

# Mock flight search: any day in this range returns catalogue offers.
MOCK_SEARCH_START = date(2026, 7, 15)
MOCK_SEARCH_END = date(2026, 9, 30)

SEED_WINDOW_START = datetime(2026, 7, 15, 0, 0, tzinfo=UTC)
SEED_WINDOW_END = datetime(2026, 9, 30, 23, 59, tzinfo=UTC)


def mock_search_date_allowed(target: date) -> bool:
    return MOCK_SEARCH_START <= target <= MOCK_SEARCH_END


def mock_departure_datetime(offer_id: str, departure_date: date) -> datetime:
    """Pick a reproducible departure time for *offer_id* on *departure_date*."""
    key = f"{offer_id}:{departure_date.isoformat()}"
    rng = random.Random(zlib.crc32(key.encode()))
    hour = rng.randint(5, 22)
    minute = rng.randint(0, 11) * 5
    return datetime(
        departure_date.year,
        departure_date.month,
        departure_date.day,
        hour,
        minute,
        tzinfo=UTC,
    )


def seed_departure_datetime(key: str) -> datetime:
    """Pick a reproducible departure within the demo window for *key*."""
    rng = random.Random(zlib.crc32(key.encode()))
    total_seconds = int((SEED_WINDOW_END - SEED_WINDOW_START).total_seconds())
    offset = rng.randint(0, total_seconds)
    departure = SEED_WINDOW_START + timedelta(seconds=offset)
    snapped_minute = (departure.minute // 5) * 5
    return departure.replace(minute=snapped_minute, second=0, microsecond=0)


def seed_departure_date(key: str) -> date:
    return seed_departure_datetime(key).date()
