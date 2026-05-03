"""Unit tests for ticket image analyzer service."""

from __future__ import annotations

import pytest

from app.services.ai.ticket_image_analyzer import analyze_ticket_image


class _FakeLLMClient:
    async def chat_json_with_image(self, *_args, **_kwargs):
        return {
            "looks_like_ticket": True,
            "warnings": ["  low contrast  ", "", None],
            "normalized_ticket_number": " tn-12 34 ",
            "raw_text": "RAW OCR TEXT",
            "extracted_fields": {
                "ticket_number": "tn-12 34",
                "passenger_name": "Jane Doe",
            },
            "field_confidence": {
                "ticket_number": 1.2,
                "passenger_name": 0.8,
                "invalid": "bad",
            },
        }


class _FakeLLMClientBadDate:
    async def chat_json_with_image(self, *_args, **_kwargs):
        return {
            "looks_like_ticket": True,
            "warnings": ["raw warning"],
            "normalized_ticket_number": "tn-1",
            "raw_text": "RAW OCR TEXT",
            "extracted_fields": {
                "ticket_number": "tn-1",
                "departure_at": "not-a-valid-datetime",
                "arrival_at": "also-bad",
            },
            "field_confidence": {
                "ticket_number": 0.9,
            },
        }


class _FakeLLMClientStringBoolFalse:
    async def chat_json_with_image(self, *_args, **_kwargs):
        return {
            "looks_like_ticket": "false",
            "warnings": ["not a ticket"],
            "normalized_ticket_number": None,
            "raw_text": "random text",
            "extracted_fields": {},
            "field_confidence": {},
        }


class _FakeLLMClientInvalidPayloadType:
    async def chat_json_with_image(self, *_args, **_kwargs):
        return ["not", "a", "json", "object"]


@pytest.mark.asyncio
async def test_analyze_ticket_image_normalizes_and_sanitizes(monkeypatch):
    monkeypatch.setattr(
        "app.services.ai.ticket_image_analyzer.get_llm_client",
        lambda: _FakeLLMClient(),
    )

    result = await analyze_ticket_image(b"\x89PNG\r\n\x1a\nx", "image/png")
    assert result.looks_like_ticket is True
    assert result.normalized_ticket_number == "TN1234"
    assert result.warnings == ["low contrast"]
    assert result.field_confidence["ticket_number"] == 1.0
    assert result.field_confidence["passenger_name"] == 0.8
    assert "invalid" not in result.field_confidence


@pytest.mark.asyncio
async def test_analyze_ticket_image_tolerates_invalid_datetime_fields(monkeypatch):
    monkeypatch.setattr(
        "app.services.ai.ticket_image_analyzer.get_llm_client",
        lambda: _FakeLLMClientBadDate(),
    )

    result = await analyze_ticket_image(b"\x89PNG\r\n\x1a\nx", "image/png")
    assert result.looks_like_ticket is True
    assert result.normalized_ticket_number == "TN1"
    assert result.extracted_fields.ticket_number == "TN1"
    assert result.extracted_fields.departure_at is None
    assert result.extracted_fields.arrival_at is None
    assert any("parsed reliably" in warning for warning in result.warnings)


@pytest.mark.asyncio
async def test_analyze_ticket_image_parses_string_false_boolean(monkeypatch):
    monkeypatch.setattr(
        "app.services.ai.ticket_image_analyzer.get_llm_client",
        lambda: _FakeLLMClientStringBoolFalse(),
    )

    result = await analyze_ticket_image(b"\x89PNG\r\n\x1a\nx", "image/png")
    assert result.looks_like_ticket is False


@pytest.mark.asyncio
async def test_analyze_ticket_image_returns_invalid_when_llm_unavailable(monkeypatch):
    def _raise():
        raise RuntimeError("missing key")

    monkeypatch.setattr(
        "app.services.ai.ticket_image_analyzer.get_llm_client",
        _raise,
    )
    result = await analyze_ticket_image(b"img", "image/png")
    assert result.looks_like_ticket is False
    assert result.warnings


@pytest.mark.asyncio
async def test_analyze_ticket_image_returns_invalid_when_payload_is_not_object(monkeypatch):
    monkeypatch.setattr(
        "app.services.ai.ticket_image_analyzer.get_llm_client",
        lambda: _FakeLLMClientInvalidPayloadType(),
    )

    result = await analyze_ticket_image(b"img", "image/png")
    assert result.looks_like_ticket is False
    assert any("invalid response" in warning.lower() for warning in result.warnings)
