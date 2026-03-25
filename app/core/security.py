"""Password hashing utilities using passlib and bcrypt."""

import hashlib

from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a plain password. Returns the hashed password."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify that plain_password matches hashed_password. Returns True if match."""
    return pwd_context.verify(plain_password, hashed_password)


def hash_keyword_token(jti: str, keyword: str) -> str:
    """Create a stable keyword hash for token lifecycle actions."""
    raw = f"{jti}:{keyword}:{settings.SECRET_KEY}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()
