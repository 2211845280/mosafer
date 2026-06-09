"""LLM-powered passport image analyzer."""

from __future__ import annotations

import re

import structlog
from pydantic import ValidationError

from app.core.config import settings
from app.schemas.passport import PassportExtractedFields, PassportImageAnalysisResult
from app.services.ai.llm_client import get_llm_client

logger = structlog.get_logger(__name__)


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


def _normalize_name(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = re.sub(r"[^A-Za-z\s\-']", " ", value).strip().upper()
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned or None


def _normalize_country_code(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = re.sub(r"[^A-Za-z]", "", value).upper()
    if len(cleaned) == 2:
        return cleaned
    if len(cleaned) == 3:
        return cleaned
    return None


def _normalize_passport_number(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = re.sub(r"[^A-Za-z0-9]", "", value).upper()
    return cleaned if len(cleaned) >= 5 else None


def _normalize_gender(value: str | None) -> str | None:
    if not value:
        return None
    upper = value.strip().upper()
    if upper in {"M", "MALE"}:
        return "M"
    if upper in {"F", "FEMALE"}:
        return "F"
    return None


async def analyze_passport_image(
    image_bytes: bytes,
    image_mime_type: str,
) -> PassportImageAnalysisResult:
    """Analyze a passport image and extract structured traveler fields."""
    try:
        client = get_llm_client()
    except RuntimeError:
        return PassportImageAnalysisResult(
            looks_like_passport=False,
            warnings=["AI passport analysis is unavailable right now."],
        )

    system_prompt = (
        "You extract passport and travel-document data from a single image. "
        "Return strict JSON with keys: "
        "looks_like_passport (boolean), warnings (string[]), raw_text (string), "
        "extracted_fields (object), field_confidence (object). "
        "For extracted_fields include keys: given_name, family_name, date_of_birth, gender, "
        "nationality, passport_number, passport_expiry, passport_issuing_country. "
        "Use UPPERCASE Latin letters for names as on the passport MRZ. "
        "Use ISO 3166-1 alpha-3 codes for nationality and passport_issuing_country when possible "
        "(or alpha-2 if only that is visible). "
        "Use gender M or F. Dates must be YYYY-MM-DD. "
        "If unsure, use null values and explain in warnings."
    )
    user_message = (
        "Analyze this image and detect if it is a real passport or travel document. "
        "Read the MRZ machine-readable zone when visible. "
        "If it is not a passport, set looks_like_passport=false and explain in warnings."
    )

    try:
        payload = await client.chat_json_with_image(
            system_prompt,
            user_message,
            image_bytes=image_bytes,
            image_mime_type=image_mime_type,
            model=settings.PASSPORT_IMAGE_ANALYSIS_MODEL,
        )
    except Exception:
        logger.exception("passport_image_analyzer.llm_failed")
        return PassportImageAnalysisResult(
            looks_like_passport=False,
            warnings=[
                "Could not analyze passport image reliably. Please retry with a clearer photo.",
            ],
        )

    if not isinstance(payload, dict):
        logger.warning(
            "passport_image_analyzer.invalid_payload_type",
            payload_type=type(payload).__name__,
        )
        return PassportImageAnalysisResult(
            looks_like_passport=False,
            warnings=["AI analysis returned an invalid response. Please retry."],
        )

    extracted_raw = payload.get("extracted_fields")
    if not isinstance(extracted_raw, dict):
        extracted_raw = {}
    warnings = _string_list(payload.get("warnings"))

    try:
        extracted = PassportExtractedFields.model_validate(extracted_raw)
    except ValidationError:
        logger.warning("passport_image_analyzer.invalid_extracted_fields")
        safe_fields = dict(extracted_raw)
        for key in ("date_of_birth", "passport_expiry"):
            safe_fields.pop(key, None)
        try:
            extracted = PassportExtractedFields.model_validate(safe_fields)
        except ValidationError:
            extracted = PassportExtractedFields()
        warnings.append("Some extracted fields could not be parsed reliably.")

    extracted.given_name = _normalize_name(extracted.given_name)
    extracted.family_name = _normalize_name(extracted.family_name)
    extracted.gender = _normalize_gender(extracted.gender)
    extracted.nationality = _normalize_country_code(extracted.nationality)
    extracted.passport_issuing_country = _normalize_country_code(
        extracted.passport_issuing_country,
    )
    extracted.passport_number = _normalize_passport_number(extracted.passport_number)

    return PassportImageAnalysisResult(
        looks_like_passport=_safe_bool(payload.get("looks_like_passport"), default=False),
        warnings=warnings,
        extracted_fields=extracted,
        field_confidence=_safe_confidence_map(payload.get("field_confidence")),
        raw_text=str(payload.get("raw_text", "") or ""),
    )
