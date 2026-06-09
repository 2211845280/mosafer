"""Seed roles, permissions, and optional superadmin account on a fresh database."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import hash_password
from app.models.admin import Admin
from app.models.permissions import Permission
from app.models.role_permissions import RolePermission
from app.models.roles import Role
from app.models.users import User

ALL_PERMISSIONS: tuple[str, ...] = (
    "flights.read",
    "flights.manage",
    "bookings.create",
    "bookings.cancel",
    "tickets.view",
    "tickets.report.view",
    "tickets.download",
    "tickets.upload",
    "tickets.validate",
    "airports.manage",
    "users.admin.manage",
    "users.profile.read",
    "users.profile.update",
    "users.profile.password",
    "users.profile.avatar",
    "admins.staff.read",
    "admins.staff.create",
    "admins.staff.update",
    "admins.staff.delete",
)

USER_ROLE_PERMISSIONS: frozenset[str] = frozenset(
    {
        "flights.read",
        "bookings.create",
        "bookings.cancel",
        "tickets.view",
    }
)


async def _ensure_permission(db: AsyncSession, name: str) -> Permission:
    result = await db.execute(select(Permission).where(Permission.name == name))
    perm = result.scalar_one_or_none()
    if perm is None:
        perm = Permission(name=name, description=name)
        db.add(perm)
        await db.flush()
    return perm


async def _ensure_role(db: AsyncSession, name: str, description: str) -> Role:
    result = await db.execute(select(Role).where(Role.name == name))
    role = result.scalar_one_or_none()
    if role is None:
        role = Role(name=name, description=description)
        db.add(role)
        await db.flush()
    return role


async def _set_role_permissions(
    db: AsyncSession,
    role: Role,
    permission_names: frozenset[str],
) -> None:
    for name in permission_names:
        perm = await _ensure_permission(db, name)
        existing = (
            await db.execute(
                select(RolePermission).where(
                    RolePermission.role_id == role.id,
                    RolePermission.permission_id == perm.id,
                )
            )
        ).scalar_one_or_none()
        if existing is None:
            db.add(RolePermission(role_id=role.id, permission_id=perm.id))


async def seed_rbac(db: AsyncSession) -> None:
    """Create baseline permissions, traveler and superadmin roles, optional admin user."""
    for name in ALL_PERMISSIONS:
        await _ensure_permission(db, name)

    user_role = await _ensure_role(db, "user", "Registered traveler")
    await _set_role_permissions(db, user_role, USER_ROLE_PERMISSIONS)

    superadmin_role = await _ensure_role(db, "superadmin", "Full system administrator")
    await _set_role_permissions(db, superadmin_role, frozenset(ALL_PERMISSIONS))

    admin_email = (settings.ADMIN_EMAIL or "").strip().lower()
    admin_password = settings.ADMIN_PASSWORD
    if not admin_email or not admin_password:
        return

    existing = await db.execute(select(User).where(User.email == admin_email))
    if existing.scalar_one_or_none() is not None:
        return

    admin_user = User(
        email=admin_email,
        password_hash=hash_password(admin_password),
        role_id=superadmin_role.id,
        is_active=True,
        is_email_verified=True,
    )
    db.add(admin_user)
    await db.flush()
    db.add(Admin(user_id=admin_user.id, full_name="System Admin", phone="n/a"))
