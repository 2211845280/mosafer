"""Pydantic schemas for the order / purchase flow."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.schemas.tickets import FlightSummaryForTicket


class OrderCreateRequest(BaseModel):
    offer_id: str = Field(..., min_length=1, description="Mock offer ID from search results")
    seat: str = Field(..., min_length=1, max_length=8, description="Seat code e.g. 12A")


class OrderResponse(BaseModel):
    reservation_id: int
    ticket_number: str
    qr_image_path: str | None
    flight: FlightSummaryForTicket
    total_price: Decimal | None
    currency: str | None
    status: str
    created_at: datetime
