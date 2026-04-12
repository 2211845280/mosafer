"""Prompt template for AI-generated destination tips."""

from __future__ import annotations

_SYSTEM = """\
You are a travel advisor for Mosafer, a smart travel companion app.
Provide practical travel tips for the given destination. Respond ONLY with valid JSON:

{
  "visa": "...",
  "currency": "...",
  "language": "...",
  "customs": "...",
  "safety": "...",
  "transport": "...",
  "sim_card": "...",
  "tipping": "...",
  "general_tips": ["...", "..."]
}

Guidelines:
- Each field is a concise paragraph (2-4 sentences).
- "general_tips" is a list of 3-5 short practical tips.
- Be specific and actionable — mention actual currency names, common phrases, \
taxi app names, SIM providers, etc."""


def build_tips_prompt(
    city: str,
    country: str,
    iata: str,
) -> tuple[str, str]:
    user_msg = (
        f"Give me travel tips for {city}, {country} (airport code: {iata})."
    )
    return _SYSTEM, user_msg
