"""Pydantic schemas for authentication operations."""

from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    """Schema for registration request."""

    name: str
    email: EmailStr
    password: str


class RegisterResponse(BaseModel):
    """Schema for registration response."""

    message: str
    user_id: int
    email: str
    verification_link: str | None = None


class LoginRequest(BaseModel):
    """Schema for login request."""

    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Schema for login response."""

    message: str
    authenticated: bool
    access_token: str | None = None
    refresh_token: str | None = None


class TokenResponse(BaseModel):
    """OAuth2-style token response (form field username = email)."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    """Schema for token refresh request."""

    refresh_token: str


class LogoutResponse(BaseModel):
    """Schema for logout response."""

    message: str


class EmailVerifyResponse(BaseModel):
    """Schema for email verification response."""

    message: str


class ForgotPasswordRequest(BaseModel):
    """Schema for forgot-password request."""

    email: EmailStr


class ForgotPasswordResponse(BaseModel):
    """Schema for forgot-password response."""

    message: str
    reset_link: str | None = None


class ResetPasswordRequest(BaseModel):
    """Schema for reset-password request."""

    token: str
    new_password: str


class ResetPasswordResponse(BaseModel):
    """Schema for reset-password response."""

    message: str
