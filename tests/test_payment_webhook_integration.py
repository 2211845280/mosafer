"""Integration tests for mock payment webhook flow."""

from __future__ import annotations

from datetime import UTC, date, timedelta

import pytest
from sqlalchemy import select

from app.models.checkout_sessions import CheckoutSession, CheckoutSessionStatus
from app.models.payments import Payment
from app.models.reservations import Reservation


@pytest.mark.asyncio
async def test_payment_webhook_materializes_paid_reservation(
    prepare_schema,
    client,
    db_session,
    seeded_checkout_payment,
):
    payment = seeded_checkout_payment
    payload = {
        "provider_payment_id": payment.provider_payment_id,
        "status": "completed",
        "signature": "mock-signature",
    }
    response = await client.post("/api/v1/payments/webhook", json=payload)
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    await db_session.refresh(payment)
    assert payment.reservation_id is not None

    refreshed = (
        await db_session.execute(
            select(Reservation).where(Reservation.id == payment.reservation_id),
        )
    ).scalar_one()
    assert refreshed.status == "paid"

    session = (
        await db_session.execute(
            select(CheckoutSession).where(CheckoutSession.id == payment.checkout_session_id),
        )
    ).scalar_one()
    assert session.status == CheckoutSessionStatus.CONSUMED.value
