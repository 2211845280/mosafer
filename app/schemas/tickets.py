"""Pydantic schemas for tickets."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class TicketRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reservation_id: int
    ticket_number: str
    qr_payload: str
    qr_image_path: str | None
    status: str
    created_at: datetime
