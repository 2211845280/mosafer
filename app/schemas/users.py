"""Pydantic schemas for user operations."""

from pydantic import BaseModel, ConfigDict, EmailStr


class UserCreate(BaseModel):
    """Schema for creating a new user."""

    email: EmailStr
    full_name: str | None = None


class UserRead(BaseModel):
    """Schema for reading user information."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str | None = None


class ProfileRead(BaseModel):
    """Schema for reading authenticated user profile."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str | None = None
    role_id: int | None = None
    is_active: bool
    avatar_path: str | None = None


class ProfileUpdateRequest(BaseModel):
    """Schema for updating user profile details."""

    full_name: str | None = None
    email: EmailStr | None = None


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
    full_name: str | None = None
    role_id: int | None = None
    is_active: bool
    avatar_path: str | None = None
