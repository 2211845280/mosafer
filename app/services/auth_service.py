"""Authentication service."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import verify_password
from app.models.users import User


async def authenticate_user(db: AsyncSession, email: str, password: str) -> dict:
    """
    Authenticate a user by email and password.

    Args:
        db: Database session.
        email: User's email address.
        password: User's password.

    Returns:
        dict with 'message', 'authenticated', and optionally 'user_id' on success.
    """
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if user is None:
        return {"message": "Invalid email or password", "authenticated": False}
    if not user.password_hash:
        return {"message": "Invalid email or password", "authenticated": False}
    if not verify_password(password, user.password_hash):
        return {"message": "Invalid email or password", "authenticated": False}
    if not user.is_active:
        return {"message": "Account is disabled", "authenticated": False}
    return {
        "message": "Login successful",
        "authenticated": True,
        "user_id": user.id,
    }
