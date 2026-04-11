"""Pydantic schemas for payments."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class PaymentCreateRequest(BaseModel):
    reservation_id: int


class PaymentSessionResponse(BaseModel):
    payment_id: int
    session_id: str
    checkout_url: str
    status: str


class PaymentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reservation_id: int
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
