"""Pydantic schemas for AI travel agent features."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

# ---------------------------------------------------------------------------
# Packing List
# ---------------------------------------------------------------------------


class PackingItem(BaseModel):
    title: str
    note: str = ""


class PackingListResult(BaseModel):
    must_have: list[PackingItem] = []
    recommended: list[PackingItem] = []
    optional: list[PackingItem] = []


# ---------------------------------------------------------------------------
# Destination Tips
# ---------------------------------------------------------------------------


class DestinationTipsResult(BaseModel):
    visa: str = ""
    currency: str = ""
    language: str = ""
    customs: str = ""
    safety: str = ""
    transport: str = ""
    sim_card: str = ""
    tipping: str = ""
    general_tips: list[str] = []


# ---------------------------------------------------------------------------
# Timeline
# ---------------------------------------------------------------------------


class TimelineItem(BaseModel):
    days_before: int
    title: str
    description: str = ""
    category: str = "task"


class TimelineResult(BaseModel):
    items: list[TimelineItem] = []


# ---------------------------------------------------------------------------
# Trip Feedback
# ---------------------------------------------------------------------------


class TripFeedbackCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    packing_helpful: bool = True
    missing_items: str | None = None
    comments: str | None = None


class TripFeedbackRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reservation_id: int
    user_id: int
    rating: int
    packing_helpful: bool
    missing_items: str | None = None
    comments: str | None = None
    created_at: datetime
