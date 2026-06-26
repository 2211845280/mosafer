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
    ids: list[int] = Field(..., min_length=1, description="List of notification IDs to mark as read")


class NotificationSendRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    body: str = Field(..., min_length=1)
    type: str = Field(default="manual", min_length=1, max_length=50)
    target_user_id: int | None = Field(
        default=None,
        description="Admin-only when different from the current user",
    )
    data: dict[str, str] | None = None


class NotificationSendResponse(BaseModel):
    notification: NotificationRead
    push_requested: bool
    push_tokens: int
    push_successes: int
