"""Pydantic schemas for payments."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class PaymentCreateRequest(BaseModel):
    checkout_session_id: int
    locale: str = "en"


class PaymentSessionResponse(BaseModel):
    payment_id: int
    session_id: str
    checkout_url: str
    status: str
    provider: str = "mock"
    publishable_key: str | None = None
    stripe_test_mode: bool = False


class PaymentConfigResponse(BaseModel):
    provider: str
    publishable_key: str | None = None
    stripe_test_mode: bool = False


class StripeVerifyRequest(BaseModel):
    session_id: str


class PaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reservation_id: int | None = None
    checkout_session_id: int | None = None
    user_id: int
    provider: str
    provider_payment_id: str
    amount: Decimal
    currency: str
    status: str
    created_at: datetime
    updated_at: datetime


class PaymentWebhookPayload(BaseModel):
    provider_payment_id: str
    status: str
    signature: str | None = None


class RefundResponse(BaseModel):
    payment_id: int
    refund_status: str
    refunded_amount: Decimal
