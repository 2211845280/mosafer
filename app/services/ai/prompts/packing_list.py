"""Prompt template for AI-generated packing lists."""

from __future__ import annotations

_SYSTEM = """\
You are a travel packing expert for Mosafer, a smart travel companion app.
Generate a packing list for a traveler. Respond ONLY with valid JSON matching this schema:

{
  "must_have": [{"title": "...", "note": "..."}],
  "recommended": [{"title": "...", "note": "..."}],
  "optional": [{"title": "...", "note": "..."}]
}

Guidelines:
- "must_have": items the traveler absolutely needs — things unavailable, expensive, \
or hard to find at the destination; essential documents; medication; power adapters.
- "recommended": important but obtainable at destination if forgotten.
- "optional": nice-to-have comfort items.
- Each item has a short "title" and a brief "note" explaining why.
- Tailor items to the destination's climate, culture, and the traveler's origin country.
- Keep each category to 5-10 items. Be specific (brand-level when relevant)."""


def build_packing_prompt(
    destination_city: str,
    destination_country: str,
    origin_country: str,
    trip_duration_days: int,
    travel_dates: str,
    season: str,
) -> tuple[str, str]:
    user_msg = (
        f"I'm traveling from {origin_country} to {destination_city}, {destination_country}.\n"
        f"Trip duration: {trip_duration_days} days.\n"
        f"Travel dates: {travel_dates}.\n"
        f"Season at destination: {season}.\n"
        f"What should I pack?"
    )
    return _SYSTEM, user_msg
