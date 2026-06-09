"""Tests for stateless passport analyze API."""

from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_passport_analyze_endpoint(prepare_schema, client, authed_user, monkeypatch):
    from app.services.ai import passport_image_analyzer as analyzer_module

    class _FakeLLMClient:
        async def chat_json_with_image(self, *_args, **_kwargs):
            return {
                "looks_like_passport": True,
                "warnings": [],
                "raw_text": "MRZ",
                "extracted_fields": {
                    "given_name": "JOHN",
                    "family_name": "DOE",
                    "date_of_birth": "1990-01-01",
                    "gender": "M",
                    "nationality": "LBY",
                    "passport_number": "AC74699",
                    "passport_expiry": "2031-05-07",
                    "passport_issuing_country": "LBY",
                },
                "field_confidence": {},
            }

    monkeypatch.setattr(analyzer_module, "get_llm_client", lambda: _FakeLLMClient())

    _, headers = authed_user
    png_header = b"\x89PNG\r\n\x1a\n" + b"x" * 64
    files = {"file": ("passport.png", png_header, "image/png")}
    response = await client.post(
        "/api/v1/passport/analyze",
        files=files,
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["looks_like_passport"] is True
    assert body["extracted_fields"]["passport_number"] == "AC74699"
    assert body["extracted_fields"]["given_name"] == "JOHN"
