"""Localized notification title/body helpers."""

from __future__ import annotations

from decimal import Decimal
from typing import Literal

TripTodoVariant = Literal["empty", "incomplete"]


def payment_success_copy(locale: str, amount: Decimal, currency: str) -> tuple[str, str]:
    if locale.lower().startswith("ar"):
        return (
            "تم الدفع بنجاح",
            f"تمت معالجة دفعتك بمبلغ {amount} {currency}.",
        )
    return (
        "Payment Successful",
        f"Your payment of {amount} {currency} has been processed.",
    )


def payment_failed_copy(locale: str) -> tuple[str, str]:
    if locale.lower().startswith("ar"):
        return ("فشل الدفع", "تعذّر معالجة دفعتك.")
    return ("Payment Failed", "Your payment could not be processed.")


def payment_refunded_copy(locale: str, amount: Decimal, currency: str) -> tuple[str, str]:
    if locale.lower().startswith("ar"):
        return (
            "تم استرداد الدفع",
            f"تم استرداد {amount} {currency} إلى حسابك.",
        )
    return (
        "Payment Refunded",
        f"Your payment of {amount} {currency} has been refunded.",
    )


def trip_todo_reminder_copy(
    locale: str,
    *,
    variant: TripTodoVariant,
    flight_label: str,
) -> tuple[str, str]:
    if locale.lower().startswith("ar"):
        title = "تذكير بمهام الرحلة"
        if variant == "empty":
            body = f"عليك تعبئة قائمة مهام الرحلة {flight_label}."
        else:
            body = f"عليك إكمال مهام الرحلة {flight_label}."
        return title, body

    title = "Trip tasks reminder"
    if variant == "empty":
        body = f"Please fill in your trip task list for {flight_label}."
    else:
        body = f"Please complete your trip tasks for {flight_label}."
    return title, body


def departure_schedule_copy(locale: str, event_type: str, flight_label: str) -> tuple[str, str]:
    """Copy for scheduled departure reminders (flight / home leave)."""
    if locale.lower().startswith("ar"):
        return _departure_schedule_copy_ar(event_type, flight_label)
    return _departure_schedule_copy_en(event_type, flight_label)


def _departure_schedule_copy_ar(event_type: str, flight_label: str) -> tuple[str, str]:
    if event_type == "flight_departure_6h":
        return (
            "تذكير بموعد المغادرة",
            f"تبقى على موعد رحلتك {flight_label} 6 ساعات.",
        )
    if event_type == "home_departure_2h":
        return (
            "تذكير بموعد المغادرة",
            f"تبقى على موعد المغادرة من المنزل نحو المطار ساعتين ({flight_label}).",
        )
    if event_type == "home_departure_30m":
        return (
            "تذكير بموعد المغادرة",
            f"تبقى على المغادرة من المنزل نصف ساعة ({flight_label}).",
        )
    if event_type == "home_departure_critical":
        return (
            "موعد المغادرة الحاسم",
            f"يجب المغادرة حالاً من المنزل نحو المطار ({flight_label}).",
        )
    return (
        "تذكير بموعد المغادرة",
        f"تذكير متعلق برحلتك {flight_label}.",
    )


def _departure_schedule_copy_en(event_type: str, flight_label: str) -> tuple[str, str]:
    if event_type == "flight_departure_6h":
        return (
            "Departure time reminder",
            f"Your flight {flight_label} departs in 6 hours.",
        )
    if event_type == "home_departure_2h":
        return (
            "Departure time reminder",
            f"Leave home for the airport in 2 hours ({flight_label}).",
        )
    if event_type == "home_departure_30m":
        return (
            "Departure time reminder",
            f"Leave home in 30 minutes ({flight_label}).",
        )
    if event_type == "home_departure_critical":
        return (
            "Critical departure time",
            f"Leave home for the airport now ({flight_label}).",
        )
    return (
        "Departure time reminder",
        f"Reminder for your trip {flight_label}.",
    )
