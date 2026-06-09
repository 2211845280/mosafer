"""User management API router."""

from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
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
from app.schemas.passport import PassportAnalyzeResponse
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
from app.services.ai.passport_image_analyzer import analyze_passport_image
from app.services.passport_profile import apply_passport_extraction, passport_details_from_passenger

router = APIRouter()

_IMAGE_UPLOAD_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}

_IMAGE_MEDIA_TYPES = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
}


def _is_real_passport_path(value: str | None) -> bool:
    return bool(value) and not value.startswith("placeholder://")


async def _ensure_passenger(db: AsyncSession, user: User) -> Passenger:
    if user.passenger is not None:
        return user.passenger
    passenger = Passenger(
        user_id=user.id,
        full_name=user.email.split("@")[0] or "Unknown User",
        phone="unknown",
        passport_image="placeholder://pending",
        account_status="active",
    )
    db.add(passenger)
    await db.flush()
    user.passenger = passenger
    return passenger


async def _load_user_with_profile(db: AsyncSession, user_id: int) -> User | None:
    """Load a user with their passenger/admin profile eagerly."""
    result = await db.execute(
        select(User)
        .where(User.id == user_id)
        .options(selectinload(User.passenger), selectinload(User.admin))
    )
    return result.scalar_one_or_none()


def _admin_user_read(user: User) -> AdminUserRead:
    data = AdminUserRead.model_validate(user).model_dump()
    if user.passenger is not None:
        passenger_data = data.get("passenger")
        if isinstance(passenger_data, dict):
            passenger_data["passport_details"] = passport_details_from_passenger(
                user.passenger,
            )
    return AdminUserRead(**data)


async def _profile_read(db: AsyncSession, user: User) -> ProfileRead:
    role_name: str | None = None
    if user.role_id is not None:
        role_result = await db.execute(select(Role.name).where(Role.id == user.role_id))
        role_name = role_result.scalar_one_or_none()
    data = ProfileRead.model_validate(user).model_dump()
    data["role_name"] = role_name
    if user.passenger is not None:
        passenger_data = data.get("passenger")
        if isinstance(passenger_data, dict):
            passenger_data["passport_details"] = passport_details_from_passenger(
                user.passenger,
            )
    return ProfileRead(**data)


@router.get("/users/me", response_model=ProfileRead)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileRead:
    """Return current authenticated user profile."""
    user = await _load_user_with_profile(db, current_user.id)
    return await _profile_read(db, user)


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
    return await _profile_read(db, updated)


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
    if file.content_type not in _IMAGE_UPLOAD_TYPES:
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
    filename = f"{current_user.id}_{uuid4().hex}{_IMAGE_UPLOAD_TYPES[file.content_type]}"
    saved_path = base_dir / filename
    saved_path.write_bytes(content)

    current_user.avatar_path = saved_path.as_posix()
    db.add(current_user)
    await db.commit()

    updated = await _load_user_with_profile(db, current_user.id)
    return await _profile_read(db, updated)


@router.post("/users/me/passport", response_model=ProfileRead)
async def upload_my_passport(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProfileRead:
    """Upload and store authenticated user's passport image."""
    if file.content_type not in _IMAGE_UPLOAD_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type",
        )

    content = await file.read()
    if len(content) > settings.PASSPORT_IMAGE_MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File is too large",
        )
    if not has_valid_magic_bytes(content, file.content_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match declared type",
        )

    user = await _load_user_with_profile(db, current_user.id)
    passenger = await _ensure_passenger(db, user)

    base_dir = Path(settings.PASSPORT_IMAGES_DIR)
    base_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{current_user.id}_{uuid4().hex}{_IMAGE_UPLOAD_TYPES[file.content_type]}"
    saved_path = base_dir / filename
    saved_path.write_bytes(content)

    passenger.passport_image = saved_path.as_posix()

    analysis = await analyze_passport_image(content, file.content_type or "image/jpeg")
    apply_passport_extraction(passenger, analysis)

    db.add(passenger)
    await db.commit()

    updated = await _load_user_with_profile(db, current_user.id)
    return await _profile_read(db, updated)


@router.post("/passport/analyze", response_model=PassportAnalyzeResponse)
async def analyze_passport_for_booking(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
) -> PassportAnalyzeResponse:
    """Extract passport fields from an image without saving to profile."""
    _ = current_user
    if file.content_type not in _IMAGE_UPLOAD_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file type",
        )

    content = await file.read()
    if len(content) > settings.PASSPORT_IMAGE_MAX_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File is too large",
        )
    if not has_valid_magic_bytes(content, file.content_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match declared type",
        )

    analysis = await analyze_passport_image(content, file.content_type or "image/jpeg")
    return PassportAnalyzeResponse(
        looks_like_passport=analysis.looks_like_passport,
        extracted_fields=analysis.extracted_fields,
        warnings=analysis.warnings,
    )


@router.get("/users/me/avatar")
async def get_my_avatar(
    current_user: User = Depends(get_current_user),
) -> FileResponse:
    """Return authenticated user's profile picture."""
    if not current_user.avatar_path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile picture not found",
        )

    avatar_file = Path(current_user.avatar_path)
    if not avatar_file.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile picture not found",
        )

    media_type = _IMAGE_MEDIA_TYPES.get(
        avatar_file.suffix.lower(),
        "application/octet-stream",
    )
    return FileResponse(avatar_file, media_type=media_type)


@router.get("/users/me/passport")
async def get_my_passport(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> FileResponse:
    """Return authenticated user's passport image."""
    user = await _load_user_with_profile(db, current_user.id)
    if user is None or user.passenger is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Passport image not found",
        )

    passport_path = user.passenger.passport_image
    if not _is_real_passport_path(passport_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Passport image not found",
        )

    passport_file = Path(passport_path)
    if not passport_file.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Passport image not found",
        )

    media_type = _IMAGE_MEDIA_TYPES.get(
        passport_file.suffix.lower(),
        "application/octet-stream",
    )
    return FileResponse(passport_file, media_type=media_type)


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
    passengers_only: bool = Query(True),
) -> PaginatedResponse[AdminUserRead]:
    """Admin endpoint to list all users with pagination."""
    base = select(User)
    count_stmt = select(func.count()).select_from(User)
    if passengers_only:
        base = base.where(~User.admin.has())
        count_stmt = count_stmt.where(~User.admin.has())

    total = (await db.execute(count_stmt)).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        base.offset(offset)
        .limit(page_size)
        .options(selectinload(User.passenger), selectinload(User.admin))
    )
    items = [_admin_user_read(user) for user in result.scalars().all()]
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)


@router.get(
    "/users/admin/{user_id}",
    response_model=AdminUserRead,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
) -> AdminUserRead:
    """Return a single user (admin) with passenger/admin profile."""
    user = await _load_user_with_profile(db, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return _admin_user_read(user)


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
    return _admin_user_read(user)


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
    return _admin_user_read(user)


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
