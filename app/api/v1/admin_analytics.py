"""Admin dashboard analytics and reservation oversight."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.jwt import get_current_user
from app.core.rbac import require_permission
from app.db.database import get_db
from app.models.users import User
from app.schemas.admin_analytics import (
    AdminDashboardResponse,
    AdminReservationRow,
    ProfitAnalyticsResponse,
    RevenueAnalyticsResponse,
)
from app.schemas.pagination import PaginatedResponse
from app.services.admin_analytics_service import (
    build_dashboard,
    build_profit_analytics,
    build_revenue_analytics,
    list_admin_reservations,
)
from app.services.admin_staff_service import user_is_superadmin

router = APIRouter()


@router.get(
    "/admin/dashboard",
    response_model=AdminDashboardResponse,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AdminDashboardResponse:
    """Revenue, bookings, and usage analytics for the admin home screen."""
    return await build_dashboard(db, user=current_user)


@router.get(
    "/admin/analytics/revenue",
    response_model=RevenueAnalyticsResponse,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_revenue_analytics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> RevenueAnalyticsResponse:
    """Detailed revenue breakdown — superadmin only."""
    if not await user_is_superadmin(db, current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only superadmin can view revenue analytics",
        )
    return await build_revenue_analytics(db)


@router.get(
    "/admin/analytics/profit",
    response_model=ProfitAnalyticsResponse,
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_profit_analytics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProfitAnalyticsResponse:
    """Detailed profit breakdown — superadmin only."""
    if not await user_is_superadmin(db, current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only superadmin can view profit analytics",
        )
    return await build_profit_analytics(db)


@router.get(
    "/admin/reservations",
    response_model=PaginatedResponse[AdminReservationRow],
    dependencies=[Depends(require_permission("users.admin.manage"))],
)
async def admin_list_reservations(
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
) -> PaginatedResponse[AdminReservationRow]:
    """Paginated reservations with payment status for admin bookings page."""
    items, total = await list_admin_reservations(db, page=page, page_size=page_size)
    return PaginatedResponse.create(items=items, total=total, page=page, page_size=page_size)
