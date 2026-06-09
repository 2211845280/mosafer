"""Request locale helpers."""

from __future__ import annotations


def resolve_request_locale(accept_language: str | None) -> str:
    """Parse Accept-Language header into supported app locale (ar or en)."""
    if not accept_language:
        return "en"

    primary = accept_language.split(",")[0].strip().lower()
    if primary.startswith("ar"):
        return "ar"
    return "en"
