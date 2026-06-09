"""Payment provider factory (mock vs Stripe)."""

from __future__ import annotations

from app.core.config import settings
from app.services.external.mock_payment_service import MockPaymentService
from app.services.external.stripe_payment_service import StripePaymentService

_mock = MockPaymentService()
_stripe: StripePaymentService | None = None


def get_payment_service() -> MockPaymentService | StripePaymentService:
    global _stripe
    if settings.payment_provider_is_stripe:
        if _stripe is None:
            _stripe = StripePaymentService()
        return _stripe
    return _mock


def active_payment_provider() -> str:
    if settings.payment_provider_is_stripe:
        return "stripe"
    return "mock"
