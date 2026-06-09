"""Stripe Checkout Sessions for flight ticket payments."""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)


class StripePaymentService:
    """Creates Stripe Checkout sessions and verifies webhooks."""

    def __init__(self) -> None:
        if not settings.STRIPE_SECRET_KEY:
            raise RuntimeError("STRIPE_SECRET_KEY is required when PAYMENT_PROVIDER=stripe")
        import stripe

        stripe.api_key = settings.STRIPE_SECRET_KEY
        self._stripe = stripe

    async def create_session(
        self,
        amount: Decimal,
        currency: str,
        reservation_id: int,
        user_id: int,
        *,
        payment_id: int,
        locale: str = "en",
    ) -> dict[str, Any]:
        web_base = settings.WEB_APP_URL.rstrip("/")
        locale_segment = locale if locale in {"en", "ar"} else "en"
        success_url = (
            f"{web_base}/{locale_segment}/book/payment-return"
            f"?session_id={{CHECKOUT_SESSION_ID}}"
            f"&reservation_id={reservation_id}"
            f"&payment_id={payment_id}"
        )
        cancel_url = (
            f"{web_base}/{locale_segment}/book/passengers"
            f"?reservation_id={reservation_id}&payment=canceled"
        )

        unit_amount = int((amount * 100).quantize(Decimal("1")))
        if unit_amount < 50:
            unit_amount = 50

        session = self._stripe.checkout.Session.create(
            mode="payment",
            success_url=success_url,
            cancel_url=cancel_url,
            client_reference_id=str(payment_id),
            metadata={
                "reservation_id": str(reservation_id),
                "user_id": str(user_id),
                "payment_id": str(payment_id),
            },
            line_items=[
                {
                    "price_data": {
                        "currency": currency.lower(),
                        "unit_amount": unit_amount,
                        "product_data": {
                            "name": f"Mosafer flight booking #{reservation_id}",
                            "description": "Flight ticket payment",
                        },
                    },
                    "quantity": 1,
                }
            ],
        )

        logger.info(
            "stripe_payment.session_created",
            session_id=session.id,
            reservation_id=reservation_id,
            payment_id=payment_id,
        )

        return {
            "session_id": session.id,
            "provider_payment_id": session.id,
            "checkout_url": session.url or "",
            "status": "pending",
        }

    async def verify_webhook(self, payload: dict, signature: str | None) -> dict:
        if not settings.STRIPE_WEBHOOK_SECRET:
            logger.warning("stripe_payment.webhook_secret_missing")
            return {"valid": False}

        raw_body = payload.get("_raw_body")
        if not isinstance(raw_body, (bytes, bytearray)):
            return {"valid": False}

        try:
            event = self._stripe.Webhook.construct_event(
                bytes(raw_body),
                signature or "",
                settings.STRIPE_WEBHOOK_SECRET,
            )
        except Exception as exc:
            logger.warning("stripe_payment.webhook_invalid", error=str(exc))
            return {"valid": False}

        if event.type == "checkout.session.completed":
            session = event.data.object
            return {
                "valid": True,
                "provider_payment_id": session.id,
                "status": "completed" if session.payment_status == "paid" else "failed",
            }

        return {"valid": True, "ignored": True, "event_type": event.type}

    async def retrieve_checkout_session(self, session_id: str) -> dict[str, Any]:
        session = self._stripe.checkout.Session.retrieve(session_id)
        status = "completed" if session.payment_status == "paid" else "pending"
        if session.status == "expired":
            status = "failed"
        return {
            "provider_payment_id": session.id,
            "status": status,
            "payment_status": session.payment_status,
        }

    async def get_payment_status(self, provider_payment_id: str) -> str:
        result = await self.retrieve_checkout_session(provider_payment_id)
        return str(result["status"])

    async def refund(self, provider_payment_id: str, amount: Decimal) -> dict:
        session = self._stripe.checkout.Session.retrieve(
            provider_payment_id,
            expand=["payment_intent"],
        )
        payment_intent = session.payment_intent
        intent_id = payment_intent.id if hasattr(payment_intent, "id") else payment_intent
        refund = self._stripe.Refund.create(payment_intent=intent_id)
        return {
            "refund_id": refund.id,
            "status": "refunded",
            "amount": str(amount),
        }
