"""Pydantic schemas for superadmin staff management."""

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class PermissionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str | None = None


class AdminStaffCreateRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str = Field(min_length=1, max_length=255)
    phone: str = Field(default="unknown", max_length=32)
    permission_names: list[str] = Field(min_length=1)


class AdminStaffUpdateRequest(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=255)
    phone: str | None = Field(default=None, max_length=32)
    permission_names: list[str] | None = None
    is_active: bool | None = None


class AdminStaffRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str
    phone: str
    is_active: bool
    role_name: str
    permission_names: list[str]
