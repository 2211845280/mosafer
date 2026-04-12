"""Pydantic schemas for trip todos."""

from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class TripTodoCreate(BaseModel):
    category: str = "task"
    title: str
    priority: str = "recommended"
    due_date: date | None = None


class TripTodoUpdate(BaseModel):
    title: str | None = None
    category: str | None = None
    priority: str | None = None
    is_completed: bool | None = None
    due_date: date | None = None


class TripTodoRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reservation_id: int
    user_id: int
    category: str
    title: str
    priority: str
    is_completed: bool
    due_date: date | None = None
    source: str
    created_at: datetime
