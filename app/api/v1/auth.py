"""Authentication API router."""

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.jwt import create_access_token, get_current_payload, get_current_user
from app.core.rate_limit import limiter
from app.core.security import hash_keyword_token, hash_password
from app.db.database import get_db
from app.models.passenger import Passenger
from app.models.refresh_tokens import RefreshToken
from app.models.revoked_tokens import RevokedToken
from app.models.roles import Role
from app.models.users import User
from app.schemas.auth import (
    EmailVerifyResponse,
    LoginRequest,
    LoginResponse,
    LogoutResponse,
    RefreshRequest,
    RegisterRequest,
    RegisterResponse,
    TokenResponse,
)
from app.services.auth_service import authenticate_user

router = APIRouter()


def _hash_refresh_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode()).hexdigest()


async def _create_refresh_token(db: AsyncSession, user_id: int) -> str:
    """Generate a refresh token, persist its hash, and return the raw value."""
    raw_token = secrets.token_urlsafe(48)
    token_hash = _hash_refresh_token(raw_token)
    expires_at = datetime.now(UTC) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    rt = RefreshToken(
        user_id=user_id,
        token_hash=token_hash,
        expires_at=expires_at,
    )
    db.add(rt)
    await db.flush()
    return raw_token


@router.post("/register", response_model=RegisterResponse)
@limiter.limit("5/minute")
async def register(
    request: Request,
    data: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> RegisterResponse:
    """Register a new user. Hashes password and stores user in the database."""
    hashed = hash_password(data.password)
    role_result = await db.execute(select(Role).where(Role.name == "user"))
    default_role = role_result.scalar_one_or_none()
    verification_token = uuid4().hex
    user = User(
        email=data.email,
        password_hash=hashed,
        role_id=default_role.id if default_role else None,
        is_email_verified=False,
        email_verification_token=verification_token,
    )
    db.add(user)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=409,
            detail="An account with this email already exists",
        ) from None

    passenger = Passenger(
        user_id=user.id,
        full_name=data.name,
        phone="unknown",
        passport_image="placeholder://pending",
        account_status="active",
    )
    db.add(passenger)
    await db.commit()
    await db.refresh(user)

    return RegisterResponse(
        message="Registration successful. Please verify your email.",
        user_id=user.id,
        email=user.email,
    )


@router.post("/login", response_model=LoginResponse)
@limiter.limit("10/minute")
async def login(
    request: Request,
    credentials: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    """Login endpoint. Verifies credentials and returns access + refresh tokens."""
    result = await authenticate_user(db, credentials.email, credentials.password)
    if not result["authenticated"]:
        raise HTTPException(status_code=401, detail=result["message"])
    user_id = result["user_id"]

    user_result = await db.execute(select(User).where(User.id == user_id))
    logged_in_user = user_result.scalar_one_or_none()
    if logged_in_user:
        logged_in_user.last_login = datetime.now(UTC)

    access_token = create_access_token(data={"sub": str(user_id)})
    refresh_token = await _create_refresh_token(db, user_id)
    await db.commit()
    return LoginResponse(
        message=result["message"],
        authenticated=True,
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/token", response_model=TokenResponse)
@limiter.limit("10/minute")
async def auth_token(
    request: Request,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Issue JWT using OAuth2 password form (username = email)."""
    result = await authenticate_user(db, form_data.username, form_data.password)
    if not result["authenticated"]:
        raise HTTPException(status_code=401, detail=result["message"])
    user_id = result["user_id"]
    access_token = create_access_token(data={"sub": str(user_id)})
    refresh_token = await _create_refresh_token(db, user_id)
    await db.commit()
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_tokens(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Exchange a valid refresh token for a new access + refresh token pair."""
    token_hash = _hash_refresh_token(body.refresh_token)
    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked.is_(False),
        )
    )
    stored = result.scalar_one_or_none()
    if stored is None or stored.expires_at < datetime.now(UTC):
        if stored:
            stored.revoked = True
            await db.commit()
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    stored.revoked = True

    access_token = create_access_token(data={"sub": str(stored.user_id)})
    new_refresh = await _create_refresh_token(db, stored.user_id)
    await db.commit()
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh,
        token_type="bearer",
    )


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
        revoked_at=datetime.now(UTC),
        expires_at=datetime.fromtimestamp(int(exp), tz=UTC),
    )
    db.add(revoked)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
    return LogoutResponse(message="Logout successful")


@router.post("/verify-email", response_model=EmailVerifyResponse)
async def verify_email(
    token: str = Query(..., description="Email verification token"),
    db: AsyncSession = Depends(get_db),
) -> EmailVerifyResponse:
    """Verify a user's email address using the token generated at registration."""
    result = await db.execute(
        select(User).where(User.email_verification_token == token)
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid verification token")
    if user.is_email_verified:
        return EmailVerifyResponse(message="Email already verified")

    user.is_email_verified = True
    user.email_verification_token = None
    await db.commit()
    return EmailVerifyResponse(message="Email verified successfully")
