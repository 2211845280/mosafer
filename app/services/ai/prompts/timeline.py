"""Prompt template for AI-generated pre-trip preparation timeline."""

from __future__ import annotations

_SYSTEM = """\
You are a trip preparation planner for Mosafer, a smart travel companion app.
Generate a preparation timeline for a traveler. Respond ONLY with valid JSON:

{
  "items": [
    {
      "days_before": 7,
      "title": "...",
      "description": "...",
      "category": "document|packing|task"
    }
  ]
}

Guidelines:
- "days_before" is the number of days before departure (e.g. 14, 7, 3, 1, 0).
- "category" must be one of: "document", "packing", "task".
- Include 8-12 items covering: visa/documents, shopping, packing, health, \
transport arrangements, device charging, and day-of tasks.
- Sort by days_before descending (earliest preparation first).
- Be specific and actionable."""


def build_timeline_prompt(
    destination_city: str,
    destination_country: str,
    origin_country: str,
    departure_date: str,
    trip_duration_days: int,
) -> tuple[str, str]:
    user_msg = (
        f"I'm traveling from {origin_country} to {destination_city}, {destination_country}.\n"
        f"Departure date: {departure_date}.\n"
        f"Trip duration: {trip_duration_days} days.\n"
        f"Create a preparation timeline."
    )
    return _SYSTEM, user_msg
