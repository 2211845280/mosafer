"""Packing list generator using LLM.

Falls back to a minimal default list when the OpenAI key is not set
or the API call fails.
"""

from __future__ import annotations

import structlog

from app.schemas.ai import PackingItem, PackingListResult
from app.services.ai.llm_client import get_llm_client
from app.services.ai.prompts.packing_list import build_packing_prompt

logger = structlog.get_logger(__name__)

_DEFAULT_LIST = PackingListResult(
    must_have=[
        PackingItem(title="Passport / ID", note="Check validity (6+ months)"),
        PackingItem(title="Phone charger & adapter", note="Verify plug type for destination"),
        PackingItem(title="Medications", note="Bring prescriptions in original packaging"),
    ],
    recommended=[
        PackingItem(title="Comfortable walking shoes", note="Break them in before the trip"),
        PackingItem(title="Reusable water bottle", note="Stay hydrated"),
    ],
    optional=[
        PackingItem(title="Travel pillow", note="For long flights"),
    ],
)


def _season_from_month(month: int, latitude: float) -> str:
    """Rough season based on month and hemisphere."""
    is_southern = latitude < 0
    if month in (12, 1, 2):
        return "summer" if is_southern else "winter"
    if month in (3, 4, 5):
        return "autumn" if is_southern else "spring"
    if month in (6, 7, 8):
        return "winter" if is_southern else "summer"
    return "spring" if is_southern else "autumn"


async def generate_packing_list(
    destination_city: str,
    destination_country: str,
    origin_country: str,
    trip_duration_days: int,
    travel_dates: str,
    destination_latitude: float = 0.0,
    departure_month: int = 6,
) -> PackingListResult:
    """Generate a packing list via the LLM, with fallback."""
    season = _season_from_month(departure_month, destination_latitude)

    try:
        client = get_llm_client()
    except RuntimeError:
        logger.warning("packing_agent.no_api_key, returning defaults")
        return _DEFAULT_LIST

    system_prompt, user_message = build_packing_prompt(
        destination_city=destination_city,
        destination_country=destination_country,
        origin_country=origin_country,
        trip_duration_days=trip_duration_days,
        travel_dates=travel_dates,
        season=season,
    )

    try:
        data = await client.chat_json(system_prompt, user_message)
        return PackingListResult(
            must_have=[PackingItem(**i) for i in data.get("must_have", [])],
            recommended=[PackingItem(**i) for i in data.get("recommended", [])],
            optional=[PackingItem(**i) for i in data.get("optional", [])],
        )
    except Exception:
        logger.exception("packing_agent.llm_failed, returning defaults")
        return _DEFAULT_LIST
