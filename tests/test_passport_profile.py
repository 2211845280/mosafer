"""Unit tests for passport profile persistence helpers."""

from __future__ import annotations

from datetime import date

from app.models.passenger import Passenger
from app.schemas.passport import PassportExtractedFields, PassportImageAnalysisResult
from app.services.passport_profile import apply_passport_extraction, passport_details_from_passenger


def test_apply_passport_extraction_persists_valid_fields():
    passenger = Passenger(
        user_id=1,
        full_name="Unknown",
        phone="unknown",
        passport_image="placeholder://pending",
        account_status="active",
    )
    analysis = PassportImageAnalysisResult(
        looks_like_passport=True,
        extracted_fields=PassportExtractedFields(
            given_name="JOHN",
            family_name="DOE",
            date_of_birth=date(1990, 1, 1),
            gender="M",
            nationality="LBY",
            passport_number="P123456",
            passport_expiry=date(2030, 12, 31),
            passport_issuing_country="LY",
        ),
    )

    assert apply_passport_extraction(passenger, analysis) is True
    assert passenger.passport_given_name == "JOHN"
    assert passenger.passport_number == "P123456"
    assert passenger.full_name == "JOHN DOE"
    assert passenger.passport_details_extracted_at is not None


def test_apply_passport_extraction_ignores_non_passport():
    passenger = Passenger(
        user_id=1,
        full_name="Unknown",
        phone="unknown",
        passport_image="placeholder://pending",
        account_status="active",
    )
    analysis = PassportImageAnalysisResult(looks_like_passport=False)

    assert apply_passport_extraction(passenger, analysis) is False
    assert passenger.passport_given_name is None


def test_passport_details_from_passenger_returns_none_when_empty():
    passenger = Passenger(
        user_id=1,
        full_name="Unknown",
        phone="unknown",
        passport_image="placeholder://pending",
        account_status="active",
    )
    assert passport_details_from_passenger(passenger) is None
