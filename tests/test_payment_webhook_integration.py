"""Integration tests for mock payment webhook flow."""

from __future__ import annotations

import pytest
from sqlalchemy import select

from app.models.reservations import Reservation


@pytest.mark.asyncio
async def test_payment_webhook_marks_reservation_paid(
    prepare_schema, client, db_session, seeded_payment
):
    payload = {
        "provider_payment_id": seeded_payment.provider_payment_id,
        "status": "completed",
        "signature": "mock-signature",
    }
    response = await client.post("/api/v1/payments/webhook", json=payload)
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    refreshed = (
        await db_session.execute(
            select(Reservation).where(Reservation.id == seeded_payment.reservation_id)
        )
    ).scalar_one()
    assert refreshed.status == "paid"
