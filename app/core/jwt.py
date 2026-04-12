"""JWT utilities for access token creation and verification."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import hash_keyword_token
from app.db.database import get_db
from app.models.revoked_tokens import RevokedToken
from app.models.users import User

# HTTP bearer: Swagger UI shows one "Authorize" field for the JWT (no OAuth2 password grant UI).
http_bearer = HTTPBearer(
    auto_error=False,
    scheme_name="JWT",
    bearerFormat="JWT",
<<<<<<< HEAD
    description="Paste the access_token from POST /api/v1/auth/login or POST /api/v1/auth/token.",
=======
    description="Paste the access_token from POST /auth/login or POST /auth/token.",
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
)


def create_access_token(data: dict) -> str:
    """
    Generate a JWT access token for authenticated users.

    Args:
        data: Payload dict; typically includes 'sub' (subject, e.g. user id).

    Returns:
        Encoded JWT string.
    """
    to_encode = data.copy()
    to_encode["jti"] = str(uuid4())
    to_encode["iat"] = datetime.now(UTC)
    expire = datetime.now(UTC) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
    )
    to_encode["exp"] = expire
    return jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


def verify_token(token: str) -> dict | None:
    """
    Decode and validate a JWT token.

    Args:
        token: JWT string.

    Returns:
        Payload dict if valid, None if invalid or expired.
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
        return payload
    except jwt.PyJWTError:
        return None


async def is_token_revoked(db: AsyncSession, jti: str) -> bool:
    """Check whether a token has been revoked."""
    execute_hash = hash_keyword_token(jti, "execute")
    revoked = await db.execute(
        select(RevokedToken).where(RevokedToken.execute_hash == execute_hash),
    )
    return revoked.scalar_one_or_none() is not None


async def get_current_payload(
    credentials: HTTPAuthorizationCredentials | None = Depends(http_bearer),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """FastAPI dependency: decode token, validate blacklist, return payload."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None or not credentials.credentials:
        raise credentials_exception
    token = credentials.credentials
    payload = verify_token(token)
    if payload is None:
        raise credentials_exception
    sub = payload.get("sub")
    jti = payload.get("jti")
    if sub is None or jti is None:
        raise credentials_exception
    if await is_token_revoked(db, str(jti)):
        raise credentials_exception
    return payload


async def get_current_user(
    payload: dict = Depends(get_current_payload),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    FastAPI dependency: extract the authenticated user from the JWT token.

    Returns:
        The User instance for the token's subject.

    Raises:
        HTTPException: 401 if token is invalid or user not found.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    sub = payload.get("sub")
    result = await db.execute(select(User).where(User.id == int(sub)))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise credentials_exception
    return user
