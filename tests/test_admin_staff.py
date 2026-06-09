"""Tests for superadmin seed migration helpers and staff API."""

from __future__ import annotations

import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import create_access_token
from app.core.security import hash_password, verify_password
from app.models.admin import Admin
from app.models.permissions import Permission
from app.models.role_permissions import RolePermission
from app.models.roles import Role
from app.models.users import User
from app.services.admin_staff_service import create_admin_staff, user_is_superadmin


async def _grant_all_permissions(db: AsyncSession, role: Role) -> None:
    perms = (await db.execute(select(Permission))).scalars().all()
    for perm in perms:
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
    await db.flush()


@pytest.mark.asyncio
async def test_create_admin_staff_with_permissions(prepare_schema, db_session: AsyncSession):
    super_role = (
        await db_session.execute(select(Role).where(Role.name == "superadmin"))
    ).scalar_one_or_none()
    if super_role is None:
        super_role = Role(name="superadmin", description="super")
        db_session.add(super_role)
        await db_session.flush()

    for name in (
        "admins.staff.create",
        "admins.staff.read",
        "users.admin.manage",
        "flights.read",
    ):
        existing = (
            await db_session.execute(select(Permission).where(Permission.name == name))
        ).scalar_one_or_none()
        if existing is None:
            db_session.add(Permission(name=name, description=name))
    await db_session.flush()
    await _grant_all_permissions(db_session, super_role)

    user, admin, role, perms = await create_admin_staff(
        db_session,
        email="staff@example.com",
        password="Secret123!",
        full_name="Staff User",
        phone="+218",
        permission_names=["flights.read", "users.admin.manage"],
        allow_staff_management=False,
    )
    await db_session.commit()

    assert user.email == "staff@example.com"
    assert admin.full_name == "Staff User"
    assert role.name.startswith("staff-")
    assert "flights.read" in perms
    assert "users.profile.read" in perms
    assert verify_password("Secret123!", user.password_hash)


@pytest.mark.asyncio
async def test_superadmin_staff_api(prepare_schema, client: AsyncClient, db_session: AsyncSession):
    super_role = (
        await db_session.execute(select(Role).where(Role.name == "superadmin"))
    ).scalar_one_or_none()
    if super_role is None:
        super_role = Role(name="superadmin", description="super")
        db_session.add(super_role)
        await db_session.flush()

    for name in (
        "admins.staff.read",
        "admins.staff.create",
        "admins.staff.update",
        "admins.staff.delete",
        "users.admin.manage",
        "flights.read",
    ):
        existing = (
            await db_session.execute(select(Permission).where(Permission.name == name))
        ).scalar_one_or_none()
        if existing is None:
            db_session.add(Permission(name=name, description=name))
    await db_session.flush()
    await _grant_all_permissions(db_session, super_role)

    super_user = User(
        email=f"super-{uuid.uuid4().hex[:6]}@example.com",
        password_hash=hash_password("SuperPass123!"),
        role_id=super_role.id,
        is_active=True,
        is_email_verified=True,
    )
    db_session.add(super_user)
    await db_session.flush()
    db_session.add(Admin(user_id=super_user.id, full_name="Super", phone="n/a"))
    await db_session.commit()

    assert await user_is_superadmin(db_session, super_user)

    token = create_access_token({"sub": str(super_user.id)})
    headers = {"Authorization": f"Bearer {token}"}

    create_res = await client.post(
        "/api/v1/admin/staff",
        json={
            "email": "newadmin@example.com",
            "password": "AdminPass123!",
            "full_name": "New Admin",
            "phone": "123",
            "permission_names": ["flights.read", "users.admin.manage"],
        },
        headers=headers,
    )
    assert create_res.status_code == 201
    body = create_res.json()
    assert body["email"] == "newadmin@example.com"
    assert "flights.read" in body["permission_names"]

    list_res = await client.get("/api/v1/admin/staff", headers=headers)
    assert list_res.status_code == 200
    assert any(row["email"] == "newadmin@example.com" for row in list_res.json())
