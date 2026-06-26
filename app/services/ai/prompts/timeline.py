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
- The traveler already has a confirmed paid booking. NEVER suggest booking flights, \
tickets, or arranging airport transport because the reservation already exists.
- Forbidden examples (do not output anything like these): "Book flight tickets", \
"احجز تذاكر الطيران", "Arrange transportation", "ترتيب وسائل النقل", \
"Book airport taxi" more than 1 day before departure.
- Instead suggest: confirm booking details, check passport/visa, create packing list, \
review departure plan, charge devices, and head to the airport on departure day.
- Transport-related tasks may only appear at days_before 0 or 1.
- Include 6-10 items covering: visa/documents, packing, health, device charging, \
and day-of tasks.
- Sort by days_before descending (earliest preparation first).
- Be specific and actionable."""


def _language_instruction(locale: str) -> str:
    if locale == "ar":
        return "\nWrite all title and description fields in Modern Standard Arabic."
    return "\nWrite all title and description fields in English."


def build_timeline_prompt(
    destination_city: str,
    destination_country: str,
    origin_country: str,
    departure_date: str,
    trip_duration_days: int,
    locale: str = "en",
) -> tuple[str, str]:
    user_msg = (
        f"I'm traveling from {origin_country} to {destination_city}, {destination_country}.\n"
        f"Departure date: {departure_date}.\n"
        f"Trip duration: {trip_duration_days} days.\n"
        f"My flight is already booked and paid.\n"
        f"Create a preparation timeline for an existing reservation."
    )
    return _SYSTEM + _language_instruction(locale), user_msg
