"""Integration tests for ticket image scan endpoint."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from app.core.config import settings
from app.schemas.tickets import TicketImageAnalysisResult, TicketImageExtractedFields

_PNG_BYTES = b"\x89PNG\r\n\x1a\n" + b"ticket-image"


@pytest.mark.asyncio
async def test_scan_ticket_image_invalid_ticket_decision(
    prepare_schema,
    client,
    authed_user,
    monkeypatch,
):
    _, headers = authed_user

    async def _fake_analyze(*_args, **_kwargs):
        return TicketImageAnalysisResult(
            looks_like_ticket=False,
            warnings=["Image does not contain a ticket."],
        )

    monkeypatch.setattr("app.api.v1.tickets.analyze_ticket_image", _fake_analyze)

    response = await client.post(
        "/api/v1/tickets/scan-image",
        files={"file": ("ticket.png", _PNG_BYTES, "image/png")},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["decision"] == "invalid_ticket"
    assert "ticket" in data["warnings"][0].lower()


@pytest.mark.asyncio
async def test_scan_ticket_image_expired_ticket_decision(
    prepare_schema,
    client,
    authed_user,
    seeded_ticket,
    seeded_flight,
    db_session,
    monkeypatch,
):
    _, headers = authed_user
    seeded_flight.departure_at = datetime.now(UTC) - timedelta(minutes=45)
    seeded_flight.arrival_at = datetime.now(UTC) - timedelta(minutes=5)
    await db_session.commit()

    async def _fake_analyze(*_args, **_kwargs):
        return TicketImageAnalysisResult(
            looks_like_ticket=True,
            normalized_ticket_number=seeded_ticket.ticket_number,
            extracted_fields=TicketImageExtractedFields(ticket_number=seeded_ticket.ticket_number),
        )

    monkeypatch.setattr("app.api.v1.tickets.analyze_ticket_image", _fake_analyze)

    response = await client.post(
        "/api/v1/tickets/scan-image",
        files={"file": ("ticket.png", _PNG_BYTES, "image/png")},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["decision"] == "expired_ticket"
    assert data["db_match"]["ticket_number"] == seeded_ticket.ticket_number


@pytest.mark.asyncio
async def test_scan_ticket_image_valid_ticket_decision(
    prepare_schema,
    client,
    authed_user,
    seeded_ticket,
    monkeypatch,
):
    _, headers = authed_user

    async def _fake_analyze(*_args, **_kwargs):
        return TicketImageAnalysisResult(
            looks_like_ticket=True,
            normalized_ticket_number=seeded_ticket.ticket_number,
            extracted_fields=TicketImageExtractedFields(
                ticket_number=seeded_ticket.ticket_number,
                passenger_name="Test User",
            ),
            field_confidence={"ticket_number": 0.99},
            raw_text="ticket raw text",
        )

    monkeypatch.setattr("app.api.v1.tickets.analyze_ticket_image", _fake_analyze)

    response = await client.post(
        "/api/v1/tickets/scan-image",
        files={"file": ("ticket.png", _PNG_BYTES, "image/png")},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["decision"] == "valid_ticket"
    assert data["normalized_ticket_number"] == seeded_ticket.ticket_number
    assert data["db_match"]["ticket_status"] == "valid"


@pytest.mark.asyncio
async def test_scan_ticket_image_rejects_unsupported_file_type(
    prepare_schema,
    client,
    authed_user,
):
    _, headers = authed_user
    response = await client.post(
        "/api/v1/tickets/scan-image",
        files={"file": ("ticket.txt", b"hello", "text/plain")},
        headers=headers,
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "Unsupported file type"


@pytest.mark.asyncio
async def test_scan_ticket_image_rejects_oversized_file(
    prepare_schema,
    client,
    authed_user,
    monkeypatch,
):
    _, headers = authed_user
    monkeypatch.setattr(settings, "TICKET_IMAGE_ANALYSIS_MAX_SIZE_BYTES", 10)
    response = await client.post(
        "/api/v1/tickets/scan-image",
        files={"file": ("ticket.png", _PNG_BYTES + b"x" * 32, "image/png")},
        headers=headers,
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "File too large"


@pytest.mark.asyncio
async def test_scan_ticket_image_invalid_when_departure_timezone_missing(
    prepare_schema,
    client,
    authed_user,
    seeded_ticket,
    seeded_flight,
    db_session,
    monkeypatch,
):
    _, headers = authed_user
    seeded_flight.departure_at = datetime.now()
    seeded_flight.arrival_at = datetime.now() + timedelta(hours=1)
    await db_session.commit()

    async def _fake_analyze(*_args, **_kwargs):
        return TicketImageAnalysisResult(
            looks_like_ticket=True,
            normalized_ticket_number=seeded_ticket.ticket_number,
            extracted_fields=TicketImageExtractedFields(ticket_number=seeded_ticket.ticket_number),
        )

    monkeypatch.setattr("app.api.v1.tickets.analyze_ticket_image", _fake_analyze)

    response = await client.post(
        "/api/v1/tickets/scan-image",
        files={"file": ("ticket.png", _PNG_BYTES, "image/png")},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["decision"] == "invalid_ticket"
    assert "timezone is missing" in " ".join(data["warnings"]).lower()
