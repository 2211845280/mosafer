"""Pydantic schemas for notifications."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class NotificationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    type: str
    title: str
    body: str
    read: bool
    created_at: datetime


class NotificationMarkReadRequest(BaseModel):
    ids: list[int] = Field(
        ..., min_length=1, description="List of notification IDs to mark as read"
    )
