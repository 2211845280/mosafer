"""Pydantic schemas for booking passenger details."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field


class BookingPassengerCreate(BaseModel):
    title: str = Field(..., pattern=r"^(MR|MRS|MS|MSTR|MISS)$")
    given_name: str = Field(..., min_length=1, max_length=80)
    family_name: str = Field(..., min_length=1, max_length=80)
    date_of_birth: date
    gender: str = Field(..., pattern=r"^[MF]$")
    nationality: str = Field(..., min_length=2, max_length=3)
    passport_number: str = Field(..., min_length=5, max_length=32)
    passport_expiry: date
    passport_issuing_country: str = Field(..., min_length=2, max_length=3)
    seat: str = Field(..., min_length=1, max_length=8)


class PassengerDetailsSubmit(BaseModel):
    passengers: list[BookingPassengerCreate] = Field(..., min_length=1, max_length=9)


class BookingPassengerRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sequence: int
    title: str
    given_name: str
    family_name: str
    date_of_birth: date
    gender: str
    nationality: str
    passport_number: str
    passport_expiry: date
    passport_issuing_country: str
    seat: str | None = None
    passenger_ticket_number: str | None = None
    qr_code: str | None = None
    created_at: datetime
