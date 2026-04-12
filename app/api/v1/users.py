"""User management API router."""

from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.file_validation import has_valid_magic_bytes
from app.core.jwt import get_current_user
from app.core.rbac import require_permission
from app.core.security import hash_password, verify_password
from app.db.database import get_db
from app.models.passenger import Passenger
from app.models.roles import Role
from app.models.user_preferences import UserPreference
from app.models.users import User
from app.schemas.pagination import PaginatedResponse
from app.schemas.user_preferences import UserPreferenceRead, UserPreferenceUpdate
from app.schemas.users import (
    AccountStatusRequest,
    AdminUserRead,
    ChangePasswordRequest,
    MessageResponse,
    ProfileRead,
    ProfileUpdateRequest,
    RoleChangeRequest,
)

router = APIRouter()


async def _load_user_with_profile(db: AsyncSession, user_id: int) -> User | None:
    """Load a user with their passenger/admin profile eagerly."""
    result = await db.execute(
        select(User)
        .where(User.id == user_id)
        .options(selectinload(User.passenger), selectinload(User.admin))
    )
    return result.scalar_one_or_none()


@router.get("/users/me", response_model=ProfileRead)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileRead:
    """Return current authenticated user profile."""
    user = await _load_user_with_profile(db, current_user.id)
    return ProfileRead.model_validate(user)


@router.patch("/users/me", response_model=ProfileRead)
async def update_my_profile(
    payload: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileRead:
    """Update authenticated user profile fields."""
    if payload.email is not None:
        current_user.email = str(payload.email)

    if payload.full_name is not None or payload.phone is not None:
        user = await _load_user_with_profile(db, current_user.id)
        profile = user.passenger or user.admin
        if profile is None:
            profile = Passenger(
                user_id=current_user.id,
                full_name=payload.full_name or "Unknown User",
                phone=payload.phone or "unknown",
                passport_image="placeholder://pending",
                account_status="active",
            )
            db.add(profile)
        if payload.full_name is not None:
            profile.full_name = payload.full_name
        if payload.phone is not None:
            profile.phone = payload.phone

    db.add(current_user)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        ) from None

    updated = await _load_user_with_profile(db, current_user.id)
    return ProfileRead.model_validate(updated)


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
    if not has_valid_magic_bytes(content, file.content_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match declared type",
        )

    base_dir = Path(settings.PROFILE_PICTURES_DIR)
    base_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{current_user.id}_{uuid4().hex}{allowed_types[file.content_type]}"
    saved_path = base_dir / filename
    saved_path.write_bytes(content)

    current_user.avatar_path = saved_path.as_posix()
    db.add(current_user)
    await db.commit()

    updated = await _load_user_with_profile(db, current_user.id)
    return ProfileRead.model_validate(updated)


@router.get("/users/me/preferences", response_model=UserPreferenceRead)
async def get_my_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserPreferenceRead:
    """Return current user's preferences, creating defaults if none exist."""
    result = await db.execute(
        select(UserPreference).where(UserPreference.user_id == current_user.id)
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = UserPreference(user_id=current_user.id)
        db.add(pref)
        await db.commit()
        await db.refresh(pref)
    return UserPreferenceRead.model_validate(pref)


@router.patch("/users/me/preferences", response_model=UserPreferenceRead)
async def update_my_preferences(
    payload: UserPreferenceUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserPreferenceRead:
    """Update current user's preferences (partial update)."""
    result = await db.execute(
        select(UserPreference).where(UserPreference.user_id == current_user.id)
    )
    pref = result.scalar_one_or_none()
    if pref is None:
        pref = UserPreference(user_id=current_user.id)
        db.add(pref)
        await db.flush()

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(pref, field, value.value if hasattr(value, "value") else value)

    db.add(pref)
    await db.commit()
    await db.refresh(pref)
    return UserPreferenceRead.model_validate(pref)


@router.get(
    "/users/admin",
    response_model=PaginatedResponse[AdminUserRead],
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_list_users(
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[AdminUserRead]:
    """Admin endpoint to list all users with pagination."""
    total = (await db.execute(select(func.count()).select_from(User))).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        select(User)
        .offset(offset)
        .limit(page_size)
        .options(selectinload(User.passenger), selectinload(User.admin))
    )
    items = [AdminUserRead.model_validate(user) for user in result.scalars().all()]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


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
    user = await _load_user_with_profile(db, user_id)
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

    user = await _load_user_with_profile(db, user_id)
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
