"""Tests for booking helper functions."""

from app.services.booking_utils import is_valid_seat, normalize_seat


def test_normalize_seat():
    assert normalize_seat(" 12a ") == "12A"


def test_is_valid_seat():
    assert is_valid_seat("1A")
    assert is_valid_seat("99F")
    assert not is_valid_seat("00A")
    assert not is_valid_seat("100A")
    assert not is_valid_seat("12Z")
