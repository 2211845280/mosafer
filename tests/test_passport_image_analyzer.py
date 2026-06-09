"""Unit tests for passport image analyzer service."""

from __future__ import annotations

import pytest

from app.services.ai.passport_image_analyzer import analyze_passport_image


class _FakeLLMClient:
    async def chat_json_with_image(self, *_args, **_kwargs):
        return {
            "looks_like_passport": True,
            "warnings": ["  low contrast  "],
            "raw_text": "P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<",
            "extracted_fields": {
                "given_name": "anna maria",
                "family_name": "eriksson",
                "date_of_birth": "1990-05-12",
                "gender": "female",
                "nationality": "SWE",
                "passport_number": "ab-1234567",
                "passport_expiry": "2030-01-15",
                "passport_issuing_country": "SE",
            },
            "field_confidence": {
                "passport_number": 0.95,
                "invalid": "bad",
            },
        }


class _FakeLLMClientBadDate:
    async def chat_json_with_image(self, *_args, **_kwargs):
        return {
            "looks_like_passport": True,
            "warnings": [],
            "raw_text": "MRZ",
            "extracted_fields": {
                "given_name": "JOHN",
                "family_name": "DOE",
                "date_of_birth": "not-a-date",
                "gender": "M",
                "nationality": "LBY",
                "passport_number": "P12345",
                "passport_expiry": "also-bad",
                "passport_issuing_country": "LY",
            },
            "field_confidence": {},
        }


@pytest.mark.asyncio
async def test_analyze_passport_image_normalizes_fields(monkeypatch):
    monkeypatch.setattr(
        "app.services.ai.passport_image_analyzer.get_llm_client",
        lambda: _FakeLLMClient(),
    )

    result = await analyze_passport_image(b"\x89PNG\r\n\x1a\nx", "image/png")
    assert result.looks_like_passport is True
    assert result.extracted_fields.given_name == "ANNA MARIA"
    assert result.extracted_fields.family_name == "ERIKSSON"
    assert result.extracted_fields.gender == "F"
    assert result.extracted_fields.passport_number == "AB1234567"
    assert result.extracted_fields.nationality == "SWE"
    assert result.extracted_fields.passport_issuing_country == "SE"
    assert result.field_confidence["passport_number"] == 0.95


@pytest.mark.asyncio
async def test_analyze_passport_image_tolerates_invalid_dates(monkeypatch):
    monkeypatch.setattr(
        "app.services.ai.passport_image_analyzer.get_llm_client",
        lambda: _FakeLLMClientBadDate(),
    )

    result = await analyze_passport_image(b"\x89PNG\r\n\x1a\nx", "image/png")
    assert result.looks_like_passport is True
    assert result.extracted_fields.given_name == "JOHN"
    assert result.extracted_fields.date_of_birth is None
    assert result.extracted_fields.passport_expiry is None
    assert any("parsed reliably" in warning for warning in result.warnings)


@pytest.mark.asyncio
async def test_analyze_passport_image_unavailable_llm(monkeypatch):
    def _raise():
        raise RuntimeError("missing key")

    monkeypatch.setattr(
        "app.services.ai.passport_image_analyzer.get_llm_client",
        _raise,
    )
    result = await analyze_passport_image(b"img", "image/png")
    assert result.looks_like_passport is False
    assert result.warnings
