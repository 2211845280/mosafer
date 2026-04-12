"""Mock payment service.

Simulates a payment provider with deterministic session IDs.
Swap this module for a real Stripe/PayMob client when ready.
"""

from __future__ import annotations

import hashlib
from datetime import UTC, datetime
from decimal import Decimal

import structlog

logger = structlog.get_logger(__name__)


class MockPaymentService:
    """Simulated payment provider — always succeeds."""

    async def create_session(
        self,
        amount: Decimal,
        currency: str,
        reservation_id: int,
        user_id: int,
    ) -> dict:
        raw = f"mock:{reservation_id}:{user_id}:{amount}:{currency}"
        session_id = hashlib.sha256(raw.encode()).hexdigest()[:24]
        checkout_url = f"https://mock-pay.mosafer.dev/checkout/{session_id}"

        logger.info(
            "mock_payment.session_created",
            session_id=session_id,
            amount=str(amount),
            currency=currency,
        )

        return {
            "session_id": session_id,
            "provider_payment_id": f"mock_pay_{session_id}",
            "checkout_url": checkout_url,
            "status": "pending",
        }

    async def verify_webhook(self, payload: dict, signature: str | None) -> dict:
        """Mock webhook verification — always valid."""
        logger.info("mock_payment.webhook_verified")
        return {"valid": True, **payload}

    async def get_payment_status(self, provider_payment_id: str) -> str:
        logger.info("mock_payment.status_check", provider_id=provider_payment_id)
        return "completed"

    async def refund(self, provider_payment_id: str, amount: Decimal) -> dict:
        refund_id = f"mock_refund_{provider_payment_id[-12:]}"
        logger.info(
            "mock_payment.refund",
            provider_id=provider_payment_id,
            refund_id=refund_id,
            amount=str(amount),
        )
        return {
            "refund_id": refund_id,
            "status": "refunded",
            "amount": str(amount),
            "refunded_at": datetime.now(UTC).isoformat(),
        }
