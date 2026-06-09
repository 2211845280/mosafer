"""Pydantic schemas for user operations."""

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr


class UserCreate(BaseModel):
    """Schema for creating a new user."""

    email: EmailStr


class UserRead(BaseModel):
    """Schema for reading user information."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr


class PassportDetailsRead(BaseModel):
    """Extracted passport fields stored on the passenger profile."""

    given_name: str | None = None
    family_name: str | None = None
    date_of_birth: date | None = None
    gender: str | None = None
    nationality: str | None = None
    passport_number: str | None = None
    passport_expiry: date | None = None
    passport_issuing_country: str | None = None


class PassengerRead(BaseModel):
    """Nested read for passenger profile."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    phone: str | None = None
    passport_image: str | None = None
    account_status: str = "active"
    passport_details: PassportDetailsRead | None = None


class AdminRead(BaseModel):
    """Nested read for admin profile."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    phone: str | None = None


class ProfileRead(BaseModel):
    """Schema for reading authenticated user profile."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    role_id: int | None = None
    role_name: str | None = None
    is_active: bool
    is_email_verified: bool = False
    avatar_path: str | None = None
    created_at: datetime | None = None
    last_login: datetime | None = None
    passenger: PassengerRead | None = None
    admin: AdminRead | None = None


class ProfileUpdateRequest(BaseModel):
    """Schema for updating user profile details."""

    email: EmailStr | None = None
    full_name: str | None = None
    phone: str | None = None


class ChangePasswordRequest(BaseModel):
    """Schema for changing user password."""

    current_password: str
    new_password: str


class RoleChangeRequest(BaseModel):
    """Schema for changing user role."""

    role_name: str


class AccountStatusRequest(BaseModel):
    """Schema for enabling/disabling account."""

    is_active: bool


class MessageResponse(BaseModel):
    """Schema for generic response messages."""

    message: str


class AdminUserRead(BaseModel):
    """Schema for admin user list response."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    role_id: int | None = None
    is_active: bool
    is_email_verified: bool = False
    avatar_path: str | None = None
    created_at: datetime | None = None
    last_login: datetime | None = None
    passenger: PassengerRead | None = None
    admin: AdminRead | None = None
