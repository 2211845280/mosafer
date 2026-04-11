"""Pydantic schemas for user preferences."""

from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class TransportMode(str, Enum):
    car = "car"
    train = "train"
    taxi = "taxi"
    bus = "bus"


class UserPreferenceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    home_address: str | None = None
    home_lat: float | None = None
    home_lng: float | None = None
    preferred_transport: str
    language: str
    currency: str
    notification_enabled: bool
    updated_at: datetime


class UserPreferenceUpdate(BaseModel):
    home_address: str | None = Field(default=None, max_length=500)
    home_lat: float | None = None
    home_lng: float | None = None
    preferred_transport: TransportMode | None = None
    language: str | None = Field(default=None, max_length=10)
    currency: str | None = Field(default=None, max_length=10)
    notification_enabled: bool | None = None
