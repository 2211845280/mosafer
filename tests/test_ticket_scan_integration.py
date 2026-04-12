"""Integration tests for ticket scan endpoint."""

from __future__ import annotations

import pytest


@pytest.mark.asyncio
async def test_ticket_scan_returns_ticket_data(prepare_schema, client, authed_user, seeded_ticket):
    _, headers = authed_user
    payload = {"qr_payload": seeded_ticket.ticket_number}
    response = await client.post("/api/v1/tickets/scan", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["ticket_number"] == seeded_ticket.ticket_number
    assert data["ticket_status"] in {"valid", "used", "canceled"}
