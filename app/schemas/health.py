"""Pydantic schemas for health check responses."""

from datetime import datetime

from pydantic import BaseModel


class HealthComponentStatus(BaseModel):
    name: str
    ok: bool
    detail: str | None = None
    checked_at: datetime


class HealthResponse(BaseModel):
    """Health check response schema."""

    status: str
    environment: str
    db: HealthComponentStatus
    redis: HealthComponentStatus
    external: HealthComponentStatus
