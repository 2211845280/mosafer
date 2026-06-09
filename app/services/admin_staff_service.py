"""Helpers for creating and managing admin staff accounts."""

from __future__ import annotations

import uuid

from fastapi import HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.admin import Admin
from app.models.permissions import Permission
from app.models.role_permissions import RolePermission
from app.models.roles import Role
from app.models.users import User

# Permissions only superadmin may grant to others.
_SUPERADMIN_ONLY = frozenset(
    {
        "admins.staff.read",
        "admins.staff.create",
        "admins.staff.update",
        "admins.staff.delete",
    },
)

# Baseline profile permissions every admin staff account receives.
_BASELINE_ADMIN_PERMISSIONS = frozenset(
    {
        "users.profile.read",
        "users.profile.update",
        "users.profile.password",
        "users.profile.avatar",
    },
)


async def list_assignable_permissions(db: AsyncSession) -> list[Permission]:
    result = await db.execute(select(Permission).order_by(Permission.name))
    return list(result.scalars().all())


async def get_user_permission_names(db: AsyncSession, user: User) -> list[str]:
    if user.role_id is None:
        return []
    result = await db.execute(
        select(Permission.name)
        .join(RolePermission, RolePermission.permission_id == Permission.id)
        .where(RolePermission.role_id == user.role_id)
        .order_by(Permission.name),
    )
    return [row[0] for row in result.all()]


async def user_is_superadmin(db: AsyncSession, user: User) -> bool:
    if user.role_id is None:
        return False
    result = await db.execute(
        select(Role.name).where(Role.id == user.role_id),
    )
    role_name = result.scalar_one_or_none()
    return role_name == "superadmin"


async def _validate_permission_names(
    db: AsyncSession,
    permission_names: list[str],
    *,
    allow_staff_management: bool,
) -> list[Permission]:
    unique_names = sorted(set(permission_names))
    result = await db.execute(
        select(Permission).where(Permission.name.in_(unique_names)),
    )
    found = {perm.name: perm for perm in result.scalars().all()}
    missing = [name for name in unique_names if name not in found]
    if missing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown permissions: {', '.join(missing)}",
        )
    if not allow_staff_management:
        forbidden = [name for name in unique_names if name in _SUPERADMIN_ONLY]
        if forbidden:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only superadmin can assign staff-management permissions",
            )
    return [found[name] for name in unique_names]


async def _set_role_permissions(
    db: AsyncSession,
    role_id: int,
    permissions: list[Permission],
) -> None:
    await db.execute(delete(RolePermission).where(RolePermission.role_id == role_id))
    for perm in permissions:
        db.add(RolePermission(role_id=role_id, permission_id=perm.id))


async def create_admin_staff(
    db: AsyncSession,
    *,
    email: str,
    password: str,
    full_name: str,
    phone: str,
    permission_names: list[str],
    allow_staff_management: bool,
) -> tuple[User, Admin, Role, list[str]]:
    normalized_email = email.strip().lower()
    existing = await db.execute(select(User.id).where(User.email == normalized_email))
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
        )

    requested = set(permission_names) | _BASELINE_ADMIN_PERMISSIONS
    permissions = await _validate_permission_names(
        db,
        sorted(requested),
        allow_staff_management=allow_staff_management,
    )

    role_suffix = uuid.uuid4().hex[:8]
    role = Role(
        name=f"staff-{role_suffix}",
        description=f"Admin staff role for {normalized_email}",
    )
    db.add(role)
    await db.flush()
    await _set_role_permissions(db, role.id, permissions)

    user = User(
        email=normalized_email,
        password_hash=hash_password(password),
        role_id=role.id,
        is_active=True,
        is_email_verified=True,
    )
    db.add(user)
    await db.flush()

    admin = Admin(user_id=user.id, full_name=full_name, phone=phone)
    db.add(admin)
    await db.flush()

    return user, admin, role, [perm.name for perm in permissions]


async def update_admin_staff(
    db: AsyncSession,
    *,
    user: User,
    full_name: str | None,
    phone: str | None,
    permission_names: list[str] | None,
    is_active: bool | None,
    allow_staff_management: bool,
) -> list[str]:
    if await user_is_superadmin(db, user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Superadmin account cannot be modified through staff management",
        )

    admin_result = await db.execute(select(Admin).where(Admin.user_id == user.id))
    admin = admin_result.scalar_one_or_none()
    if admin is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Admin staff profile not found",
        )

    if full_name is not None:
        admin.full_name = full_name
    if phone is not None:
        admin.phone = phone
    if is_active is not None:
        user.is_active = is_active

    if permission_names is not None:
        if user.role_id is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User has no role assigned",
            )
        requested = set(permission_names) | _BASELINE_ADMIN_PERMISSIONS
        permissions = await _validate_permission_names(
            db,
            sorted(requested),
            allow_staff_management=allow_staff_management,
        )
        await _set_role_permissions(db, user.role_id, permissions)
        perm_names = [perm.name for perm in permissions]
    else:
        perm_names = await get_user_permission_names(db, user)

    db.add(admin)
    db.add(user)
    await db.flush()
    return perm_names
