"""Apply passport image analysis results to passenger profile."""

from __future__ import annotations

from datetime import UTC, datetime

from app.models.passenger import Passenger
from app.schemas.passport import PassportImageAnalysisResult
from app.schemas.users import PassportDetailsRead


def passport_details_from_passenger(passenger: Passenger) -> PassportDetailsRead | None:
    """Build API passport details from stored passenger columns."""
    details = PassportDetailsRead(
        given_name=passenger.passport_given_name,
        family_name=passenger.passport_family_name,
        date_of_birth=passenger.passport_date_of_birth,
        gender=passenger.passport_gender,
        nationality=passenger.passport_nationality,
        passport_number=passenger.passport_number,
        passport_expiry=passenger.passport_expiry,
        passport_issuing_country=passenger.passport_issuing_country,
    )
    if not any(
        [
            details.given_name,
            details.family_name,
            details.date_of_birth,
            details.gender,
            details.nationality,
            details.passport_number,
            details.passport_expiry,
            details.passport_issuing_country,
        ]
    ):
        return None
    return details


def apply_passport_extraction(
    passenger: Passenger,
    analysis: PassportImageAnalysisResult,
) -> bool:
    """Persist validated extracted passport fields on the passenger profile."""
    if not analysis.looks_like_passport:
        return False

    fields = analysis.extracted_fields
    saved = False

    if fields.given_name and len(fields.given_name) >= 1:
        passenger.passport_given_name = fields.given_name
        saved = True
    if fields.family_name and len(fields.family_name) >= 1:
        passenger.passport_family_name = fields.family_name
        saved = True
    if fields.date_of_birth is not None:
        passenger.passport_date_of_birth = fields.date_of_birth
        saved = True
    if fields.gender in {"M", "F"}:
        passenger.passport_gender = fields.gender
        saved = True
    if fields.nationality and 2 <= len(fields.nationality) <= 3:
        passenger.passport_nationality = fields.nationality
        saved = True
    if fields.passport_number and len(fields.passport_number) >= 5:
        passenger.passport_number = fields.passport_number
        saved = True
    if fields.passport_expiry is not None:
        passenger.passport_expiry = fields.passport_expiry
        saved = True
    if fields.passport_issuing_country and 2 <= len(fields.passport_issuing_country) <= 3:
        passenger.passport_issuing_country = fields.passport_issuing_country
        saved = True

    if not saved:
        return False

    if passenger.passport_given_name and passenger.passport_family_name:
        passenger.full_name = (
            f"{passenger.passport_given_name} {passenger.passport_family_name}".strip()
        )

    passenger.passport_details_extracted_at = datetime.now(UTC)
    return True
