"""Superadmin endpoints for managing admin staff and permissions."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.jwt import get_current_user
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.admin import Admin
from app.models.role_permissions import RolePermission
from app.models.roles import Role
from app.models.users import User
from app.schemas.admin_staff import (
    AdminStaffCreateRequest,
    AdminStaffRead,
    AdminStaffUpdateRequest,
    PermissionRead,
)
from app.schemas.users import MessageResponse
from app.services.admin_staff_service import (
    create_admin_staff,
    get_user_permission_names,
    list_assignable_permissions,
    update_admin_staff,
    user_is_superadmin,
)

router = APIRouter()


def _to_staff_read(user: User, admin: Admin, role: Role, permission_names: list[str]) -> AdminStaffRead:
    return AdminStaffRead(
        id=user.id,
        email=user.email,
        full_name=admin.full_name,
        phone=admin.phone,
        is_active=user.is_active,
        role_name=role.name,
        permission_names=permission_names,
    )


@router.get(
    "/admin/permissions",
    response_model=list[PermissionRead],
    dependencies=[Depends(require_permission("admins.staff.read"))],
)
async def list_permissions(db: AsyncSession = Depends(get_db)) -> list[PermissionRead]:
    """List permissions that can be assigned to admin staff."""
    perms = await list_assignable_permissions(db)
    return [PermissionRead.model_validate(p) for p in perms]


@router.get(
    "/admin/staff",
    response_model=list[AdminStaffRead],
    dependencies=[Depends(require_permission("admins.staff.read"))],
)
async def list_admin_staff(db: AsyncSession = Depends(get_db)) -> list[AdminStaffRead]:
    """List admin staff accounts (excludes passengers)."""
    result = await db.execute(
        select(User, Admin, Role)
        .join(Admin, Admin.user_id == User.id)
        .join(Role, Role.id == User.role_id)
        .order_by(User.id),
    )
    items: list[AdminStaffRead] = []
    for user, admin, role in result.all():
        permission_names = await get_user_permission_names(db, user)
        items.append(_to_staff_read(user, admin, role, permission_names))
    return items


@router.post(
    "/admin/staff",
    response_model=AdminStaffRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("admins.staff.create"))],
)
async def create_staff(
    payload: AdminStaffCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AdminStaffRead:
    """Create a new admin staff account with selected permissions."""
    allow_staff_management = await user_is_superadmin(db, current_user)
    user, admin, role, permission_names = await create_admin_staff(
        db,
        email=str(payload.email),
        password=payload.password,
        full_name=payload.full_name,
        phone=payload.phone,
        permission_names=payload.permission_names,
        allow_staff_management=allow_staff_management,
    )
    await db.commit()
    await db.refresh(user)
    return _to_staff_read(user, admin, role, permission_names)


@router.patch(
    "/admin/staff/{user_id}",
    response_model=AdminStaffRead,
    dependencies=[Depends(require_permission("admins.staff.update"))],
)
async def update_staff(
    user_id: int,
    payload: AdminStaffUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AdminStaffRead:
    """Update admin staff profile, status, or permissions."""
    if current_user.id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot modify your own staff record here",
        )

    result = await db.execute(
        select(User)
        .where(User.id == user_id)
        .options(selectinload(User.admin)),
    )
    user = result.scalar_one_or_none()
    if user is None or user.admin is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Admin staff not found")

    role_result = await db.execute(select(Role).where(Role.id == user.role_id))
    role = role_result.scalar_one_or_none()
    if role is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role not found")

    allow_staff_management = await user_is_superadmin(db, current_user)
    permission_names = await update_admin_staff(
        db,
        user=user,
        full_name=payload.full_name,
        phone=payload.phone,
        permission_names=payload.permission_names,
        is_active=payload.is_active,
        allow_staff_management=allow_staff_management,
    )
    await db.commit()
    await db.refresh(user)
    await db.refresh(user.admin)
    return _to_staff_read(user, user.admin, role, permission_names)


@router.delete(
    "/admin/staff/{user_id}",
    response_model=MessageResponse,
    dependencies=[Depends(require_permission("admins.staff.delete"))],
)
async def delete_staff(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    """Delete an admin staff account."""
    if current_user.id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own account",
        )

    result = await db.execute(
        select(User, Role)
        .join(Role, Role.id == User.role_id)
        .where(User.id == user_id),
    )
    row = result.one_or_none()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Admin staff not found")

    user, role = row
    if await user_is_superadmin(db, user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Superadmin account cannot be deleted",
        )

    admin_result = await db.execute(select(Admin).where(Admin.user_id == user.id))
    admin = admin_result.scalar_one_or_none()
    if admin is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Admin staff not found")

    role_id = role.id
    is_staff_role = role.name.startswith("staff-")
    try:
        if is_staff_role:
            await db.execute(delete(RolePermission).where(RolePermission.role_id == role_id))
        await db.delete(admin)
        await db.delete(user)
        await db.flush()
        if is_staff_role:
            orphan_role = await db.get(Role, role_id)
            if orphan_role is not None:
                await db.delete(orphan_role)
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Could not delete admin staff due to related records",
        ) from None
    return MessageResponse(message="Admin staff deleted successfully")
