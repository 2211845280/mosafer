"""LLM-powered ticket image analyzer."""

from __future__ import annotations

import re

import structlog
from pydantic import ValidationError

from app.core.config import settings
from app.schemas.tickets import TicketImageAnalysisResult, TicketImageExtractedFields
from app.services.ai.llm_client import get_llm_client

logger = structlog.get_logger(__name__)


def _normalize_ticket_number(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = re.sub(r"[^A-Za-z0-9]", "", value).upper()
    return cleaned or None


def _safe_confidence_map(raw: object) -> dict[str, float]:
    if not isinstance(raw, dict):
        return {}
    result: dict[str, float] = {}
    for key, value in raw.items():
        if not isinstance(key, str):
            continue
        try:
            score = float(value)
        except (TypeError, ValueError):
            continue
        result[key] = max(0.0, min(1.0, score))
    return result


def _string_list(raw: object) -> list[str]:
    if not isinstance(raw, list):
        return []
    return [item.strip() for item in raw if isinstance(item, str) and item.strip()]


def _safe_bool(value: object, default: bool = False) -> bool:
    """Parse common boolean-like values safely."""
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"true", "1", "yes", "y"}:
            return True
        if lowered in {"false", "0", "no", "n", ""}:
            return False
        return default
    if isinstance(value, (int, float)):
        return bool(value)
    return default


async def analyze_ticket_image(image_bytes: bytes, image_mime_type: str) -> TicketImageAnalysisResult:
    """Analyze a ticket image and extract structured fields."""
    try:
        client = get_llm_client()
    except RuntimeError:
        return TicketImageAnalysisResult(
            looks_like_ticket=False,
            warnings=["AI image analysis is unavailable right now."],
        )

    system_prompt = (
        "You extract airline ticket data from a single image. "
        "Return strict JSON with keys: "
        "looks_like_ticket (boolean), warnings (string[]), normalized_ticket_number (string|null), "
        "raw_text (string), extracted_fields (object), field_confidence (object). "
        "For extracted_fields include keys: ticket_number, passenger_name, carrier_code, flight_number, "
        "origin_iata, destination_iata, departure_at, arrival_at, seat, ticket_status_hint. "
        "If unsure, use null values and warning messages."
    )
    user_message = (
        "Analyze this image and detect if it is a real airline ticket. "
        "If it is not a ticket, set looks_like_ticket=false and explain in warnings. "
        "When possible, normalize ticket number to uppercase alphanumeric."
    )

    try:
        payload = await client.chat_json_with_image(
            system_prompt,
            user_message,
            image_bytes=image_bytes,
            image_mime_type=image_mime_type,
            model=settings.TICKET_IMAGE_ANALYSIS_MODEL,
        )
    except Exception:
        logger.exception("ticket_image_analyzer.llm_failed")
        return TicketImageAnalysisResult(
            looks_like_ticket=False,
            warnings=["Could not analyze image reliably. Please retry with a clearer ticket image."],
        )
    if not isinstance(payload, dict):
        logger.warning("ticket_image_analyzer.invalid_payload_type", payload_type=type(payload).__name__)
        return TicketImageAnalysisResult(
            looks_like_ticket=False,
            warnings=["AI analysis returned an invalid response. Please retry with a clearer ticket image."],
        )

    extracted_raw = payload.get("extracted_fields")
    if not isinstance(extracted_raw, dict):
        extracted_raw = {}
    warnings = _string_list(payload.get("warnings"))
    try:
        extracted = TicketImageExtractedFields.model_validate(extracted_raw)
    except ValidationError:
        logger.warning("ticket_image_analyzer.invalid_extracted_fields")
        # Keep safe scalar fields and drop invalid datetimes instead of failing the whole request.
        safe_fields = dict(extracted_raw)
        safe_fields.pop("departure_at", None)
        safe_fields.pop("arrival_at", None)
        try:
            extracted = TicketImageExtractedFields.model_validate(safe_fields)
        except ValidationError:
            extracted = TicketImageExtractedFields()
        warnings.append("Some extracted fields could not be parsed reliably.")

    normalized_ticket_number = _normalize_ticket_number(payload.get("normalized_ticket_number"))
    if normalized_ticket_number is None:
        normalized_ticket_number = _normalize_ticket_number(extracted.ticket_number)
    if normalized_ticket_number is not None:
        # Keep extracted fields consistent with the normalized top-level value.
        extracted.ticket_number = normalized_ticket_number

    return TicketImageAnalysisResult(
        looks_like_ticket=_safe_bool(payload.get("looks_like_ticket"), default=False),
        warnings=warnings,
        normalized_ticket_number=normalized_ticket_number,
        extracted_fields=extracted,
        field_confidence=_safe_confidence_map(payload.get("field_confidence")),
        raw_text=str(payload.get("raw_text", "") or ""),
    )
