"""Unit tests for notification copy helpers."""

from __future__ import annotations

from app.services.notification_copy import (
    departure_schedule_copy,
    trip_todo_reminder_copy,
)


def test_trip_todo_empty_ar() -> None:
    title, body = trip_todo_reminder_copy("ar", variant="empty", flight_label="MS123")
    assert title == "تذكير بمهام الرحلة"
    assert "تعبئة" in body
    assert "MS123" in body


def test_trip_todo_incomplete_en() -> None:
    title, body = trip_todo_reminder_copy("en", variant="incomplete", flight_label="TK244")
    assert title == "Trip tasks reminder"
    assert "complete" in body.lower()
    assert "TK244" in body


def test_departure_schedule_new_types() -> None:
    title, body = departure_schedule_copy("ar", "home_departure_critical", "TK244")
    assert title == "موعد المغادرة الحاسم"
    assert "حالاً" in body

    title, body = departure_schedule_copy("en", "flight_departure_6h", "MS123")
    assert "6 hours" in body
