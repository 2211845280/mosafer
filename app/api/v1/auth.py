"""Authentication API router."""

from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import create_access_token, get_current_payload, get_current_user
from app.core.security import hash_keyword_token, hash_password
from app.db.database import get_db
from app.models.revoked_tokens import RevokedToken
from app.models.roles import Role
from app.models.users import User
from app.services.auth_service import authenticate_user

router = APIRouter()


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


class LoginRequest(BaseModel):
    """Schema for login request."""

    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Schema for login response."""

    message: str
    authenticated: bool
    access_token: str | None = None


class TokenResponse(BaseModel):
    """OAuth2-style token response (form field username = email)."""

    access_token: str
    token_type: str = "bearer"


class LogoutResponse(BaseModel):
    """Schema for logout response."""

    message: str


@router.post("/register", response_model=RegisterResponse)
async def register(
    data: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> RegisterResponse:
    """Register a new user. Hashes password and stores user in the database."""
    hashed = hash_password(data.password)
    role_result = await db.execute(select(Role).where(Role.name == "user"))
    default_role = role_result.scalar_one_or_none()
    user = User(
        email=data.email,
        full_name=data.name,
        password_hash=hashed,
        role_id=default_role.id if default_role else None,
    )
    db.add(user)
    try:
        await db.commit()
        await db.refresh(user)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=409,
            detail="An account with this email already exists",
        ) from None
    return RegisterResponse(
        message="Registration successful",
        user_id=user.id,
        email=user.email,
    )


@router.post("/login", response_model=LoginResponse)
async def login(
    credentials: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    """Login endpoint. Verifies credentials and returns access token on success."""
    result = await authenticate_user(db, credentials.email, credentials.password)
    if not result["authenticated"]:
        raise HTTPException(status_code=401, detail=result["message"])
    access_token = create_access_token(data={"sub": str(result["user_id"])})
    return LoginResponse(
        message=result["message"],
        authenticated=True,
        access_token=access_token,
    )


@router.post("/token", response_model=TokenResponse)
async def auth_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Issue JWT using OAuth2 password form (username = email)."""
    result = await authenticate_user(db, form_data.username, form_data.password)
    if not result["authenticated"]:
        raise HTTPException(status_code=401, detail=result["message"])
    access_token = create_access_token(data={"sub": str(result["user_id"])})
    return TokenResponse(access_token=access_token, token_type="bearer")


@router.post("/logout", response_model=LogoutResponse)
async def logout(
    payload: dict = Depends(get_current_payload),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> LogoutResponse:
    """Logout endpoint. Revokes current token by storing blacklist hashes."""
    jti = payload.get("jti")
    exp = payload.get("exp")
    if jti is None or exp is None:
        raise HTTPException(status_code=401, detail="Invalid token")

    revoked = RevokedToken(
        jti=str(jti),
        user_id=user.id,
        logout_hash=hash_keyword_token(str(jti), "logout"),
        execute_hash=hash_keyword_token(str(jti), "execute"),
        revoked_at=datetime.now(timezone.utc),
        expires_at=datetime.fromtimestamp(int(exp), tz=timezone.utc),
    )
    db.add(revoked)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
    return LogoutResponse(message="Logout successful")
