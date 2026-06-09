"""Pydantic schemas for passport image analysis."""

from datetime import date

from pydantic import BaseModel, Field


class PassportExtractedFields(BaseModel):
    """Structured fields extracted from a passport image."""

    given_name: str | None = None
    family_name: str | None = None
    date_of_birth: date | None = None
    gender: str | None = None
    nationality: str | None = None
    passport_number: str | None = None
    passport_expiry: date | None = None
    passport_issuing_country: str | None = None


class PassportImageAnalysisResult(BaseModel):
    """Raw LLM analysis response prior to DB validation."""

    looks_like_passport: bool = False
    warnings: list[str] = Field(default_factory=list)
    extracted_fields: PassportExtractedFields = Field(default_factory=PassportExtractedFields)
    field_confidence: dict[str, float] = Field(default_factory=dict)
    raw_text: str = ""


class PassportAnalyzeResponse(BaseModel):
    """Stateless passport OCR response for booking forms."""

    looks_like_passport: bool = False
    extracted_fields: PassportExtractedFields = Field(default_factory=PassportExtractedFields)
    warnings: list[str] = Field(default_factory=list)
