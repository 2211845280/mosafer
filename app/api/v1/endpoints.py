"""User CRUD API router."""

from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from pydantic import BaseModel, ConfigDict, EmailStr
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.jwt import get_current_user
from app.core.rbac import require_permission
from app.core.security import hash_password, verify_password
from app.db.database import get_db
from app.models.roles import Role
from app.models.users import User
from app.schemas.users import UserCreate, UserRead

router = APIRouter()


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


@router.post("/users", response_model=UserRead)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> UserRead:
    """Create a new user in the database."""
    user = User(email=user_in.email, full_name=user_in.full_name)
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@router.get("/users", response_model=list[UserRead])
async def list_users(
    db: AsyncSession = Depends(get_db),
) -> list[UserRead]:
    """List all users from the database."""
    result = await db.execute(select(User))
    users = result.scalars().all()
    return users


@router.get("/users/me", response_model=ProfileRead)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
) -> ProfileRead:
    """Return current authenticated user profile."""
    return ProfileRead.model_validate(current_user)


@router.patch("/users/me", response_model=ProfileRead)
async def update_my_profile(
    payload: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileRead:
    """Update authenticated user profile fields."""
    if payload.full_name is not None:
        current_user.full_name = payload.full_name
    if payload.email is not None:
        current_user.email = str(payload.email)

    db.add(current_user)
    try:
        await db.commit()
        await db.refresh(current_user)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        ) from None

    return ProfileRead.model_validate(current_user)


@router.post("/users/me/password", response_model=MessageResponse)
async def change_my_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """Change authenticated user password."""
    if not current_user.password_hash or not verify_password(
        payload.current_password,
        current_user.password_hash,
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )
    current_user.password_hash = hash_password(payload.new_password)
    db.add(current_user)
    await db.commit()
    return MessageResponse(message="Password changed successfully")


@router.post("/users/me/avatar", response_model=ProfileRead)
async def upload_my_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileRead:
    """Upload and store authenticated user profile picture."""
    allowed_types = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type",
        )

    content = await file.read()
    if len(content) > settings.PROFILE_PICTURE_MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File is too large",
        )

    base_dir = Path(settings.PROFILE_PICTURES_DIR)
    base_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{current_user.id}_{uuid4().hex}{allowed_types[file.content_type]}"
    saved_path = base_dir / filename
    saved_path.write_bytes(content)

    current_user.avatar_path = saved_path.as_posix()
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return ProfileRead.model_validate(current_user)


@router.get(
    "/users/admin",
    response_model=list[AdminUserRead],
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_list_users(
    db: AsyncSession = Depends(get_db),
) -> list[AdminUserRead]:
    """Admin endpoint to list all users."""
    result = await db.execute(select(User))
    users = result.scalars().all()
    return [AdminUserRead.model_validate(user) for user in users]


@router.patch(
    "/users/admin/{user_id}/enable",
    response_model=AdminUserRead,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_set_user_status(
    user_id: int,
    payload: AccountStatusRequest,
    db: AsyncSession = Depends(get_db),
) -> AdminUserRead:
    """Admin endpoint to enable or disable user accounts."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user.is_active = payload.is_active
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return AdminUserRead.model_validate(user)


@router.patch(
    "/users/admin/{user_id}/role",
    response_model=AdminUserRead,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_change_user_role(
    user_id: int,
    payload: RoleChangeRequest,
    db: AsyncSession = Depends(get_db),
) -> AdminUserRead:
    """Admin endpoint to change user role."""
    role_result = await db.execute(select(Role).where(Role.name == payload.role_name))
    role = role_result.scalar_one_or_none()
    if role is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.role_id = role.id
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return AdminUserRead.model_validate(user)


@router.delete(
    "/users/admin/{user_id}",
    response_model=MessageResponse,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_delete_user(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """Admin endpoint to delete users."""
    if current_user.id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admin cannot delete their own account",
        )

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    await db.delete(user)
    await db.commit()
    return MessageResponse(message="User deleted successfully")
