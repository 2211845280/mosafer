"""Aggregations for the admin dashboard."""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.admin import Admin
from app.models.flights import Flight
from app.models.payments import Payment
from app.models.reservations import Reservation, ReservationStatus
from app.models.tickets import Ticket, TicketStatus
from app.models.users import User
from app.schemas.admin_analytics import (
    AdminDashboardResponse,
    AdminReservationFlight,
    AdminReservationRow,
    MonthlyRevenuePoint,
    PaymentStatusBreakdown,
    ProfitAnalyticsResponse,
    RecentBookingRow,
    RevenueAnalyticsResponse,
    RouteStat,
)
from app.services.admin_staff_service import user_is_superadmin

PROFIT_MARGIN = Decimal("0.12")


def _display_booking_status(reservation_status: str, payment_status: str | None) -> str:
    del payment_status
    if reservation_status == ReservationStatus.CANCELED.value:
        return "cancelled"
    return "confirmed"


def _display_payment_status(reservation_status: str, payment_status: str | None) -> str:
    del payment_status
    if reservation_status == ReservationStatus.CANCELED.value:
        return "refunded"
    return "completed"


def _redact_financial_dashboard(response: AdminDashboardResponse) -> AdminDashboardResponse:
    """Strip revenue/profit/ticket metrics for non-superadmin viewers."""
    zero = Decimal("0")
    return response.model_copy(
        update={
            "total_revenue": zero,
            "revenue_this_month": zero,
            "platform_profit": zero,
            "profit_margin_pct": zero,
            "total_tickets": 0,
            "valid_tickets": 0,
            "used_tickets": 0,
            "monthly_revenue": [],
            "top_routes": [
                RouteStat(
                    origin_iata=r.origin_iata,
                    destination_iata=r.destination_iata,
                    bookings=r.bookings,
                    revenue=zero,
                )
                for r in response.top_routes
            ],
        },
    )


async def build_dashboard(
    db: AsyncSession,
    *,
    user: User | None = None,
) -> AdminDashboardResponse:
    now = datetime.now(UTC)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    admin_user_ids = select(Admin.user_id)
    non_admin = User.id.not_in(admin_user_ids)

    total_users = (
        await db.execute(select(func.count()).select_from(User).where(non_admin))
    ).scalar_one()
    active_users = (
        await db.execute(
            select(func.count()).select_from(User).where(non_admin, User.is_active.is_(True)),
        )
    ).scalar_one()
    staff_count = (
        await db.execute(select(func.count()).select_from(Admin))
    ).scalar_one()

    total_bookings = (
        await db.execute(select(func.count()).select_from(Reservation))
    ).scalar_one()
    paid_bookings = (
        await db.execute(
            select(func.count()).select_from(Reservation).where(
                Reservation.status == ReservationStatus.PAID.value,
            ),
        )
    ).scalar_one()
    pending_bookings = 0
    canceled_bookings = (
        await db.execute(
            select(func.count()).select_from(Reservation).where(
                Reservation.status == ReservationStatus.CANCELED.value,
            ),
        )
    ).scalar_one()

    total_revenue = (
        await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                Payment.status == "completed",
            ),
        )
    ).scalar_one()
    revenue_this_month = (
        await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                Payment.status == "completed",
                Payment.created_at >= month_start,
            ),
        )
    ).scalar_one()

    completed_payments = (
        await db.execute(
            select(func.count()).select_from(Payment).where(Payment.status == "completed"),
        )
    ).scalar_one()
    pending_payments = (
        await db.execute(
            select(func.count()).select_from(Payment).where(Payment.status == "pending"),
        )
    ).scalar_one()
    refunded_payments = (
        await db.execute(
            select(func.count()).select_from(Payment).where(Payment.status == "refunded"),
        )
    ).scalar_one()

    total_tickets = (
        await db.execute(select(func.count()).select_from(Ticket))
    ).scalar_one()
    valid_tickets = (
        await db.execute(
            select(func.count()).select_from(Ticket).where(Ticket.status == TicketStatus.VALID.value),
        )
    ).scalar_one()
    used_tickets = (
        await db.execute(
            select(func.count()).select_from(Ticket).where(Ticket.status == TicketStatus.USED.value),
        )
    ).scalar_one()

    monthly_col = func.to_char(Payment.created_at, "YYYY-MM")
    monthly_rows = (
        await db.execute(
            select(
                monthly_col.label("month"),
                func.coalesce(func.sum(Payment.amount), 0).label("revenue"),
                func.count(Payment.id).label("bookings"),
            )
            .where(Payment.status == "completed")
            .group_by(monthly_col)
            .order_by(monthly_col)
            .limit(12),
        )
    ).all()
    monthly_revenue = [
        MonthlyRevenuePoint(
            month=row.month,
            revenue=Decimal(str(row.revenue)),
            bookings=int(row.bookings),
        )
        for row in monthly_rows
    ]

    route_rows = (
        await db.execute(
            select(
                Flight.origin_iata,
                Flight.destination_iata,
                func.count(Reservation.id).label("bookings"),
                func.coalesce(func.sum(Reservation.total_price), 0).label("revenue"),
            )
            .join(Reservation, Reservation.flight_id == Flight.id)
            .where(Reservation.status == ReservationStatus.PAID.value)
            .group_by(Flight.origin_iata, Flight.destination_iata)
            .order_by(func.count(Reservation.id).desc())
            .limit(6),
        )
    ).all()
    top_routes = [
        RouteStat(
            origin_iata=row.origin_iata,
            destination_iata=row.destination_iata,
            bookings=int(row.bookings),
            revenue=Decimal(str(row.revenue)),
        )
        for row in route_rows
    ]

    recent_result = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.user),
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
        )
        .where(
            Reservation.status.in_(
                [ReservationStatus.PAID.value, ReservationStatus.CANCELED.value],
            ),
        )
        .order_by(Reservation.created_at.desc())
        .limit(8),
    )
    recent_reservations = recent_result.scalars().all()
    recent_bookings: list[RecentBookingRow] = []
    for res in recent_reservations:
        pay_result = await db.execute(
            select(Payment.status)
            .where(Payment.reservation_id == res.id)
            .order_by(Payment.created_at.desc())
            .limit(1),
        )
        payment_status = pay_result.scalar_one_or_none()
        flight = res.flight
        recent_bookings.append(
            RecentBookingRow(
                id=res.id,
                user_email=res.user.email if res.user else "unknown",
                route=f"{flight.origin_iata} → {flight.destination_iata}" if flight else "—",
                amount=res.total_price or Decimal("0"),
                currency=res.currency or "USD",
                status=_display_booking_status(res.status, payment_status),
                payment_status=_display_payment_status(res.status, payment_status),
                created_at=res.created_at.isoformat(),
            ),
        )

    total_revenue_dec = Decimal(str(total_revenue))
    revenue_month_dec = Decimal(str(revenue_this_month))

    response = AdminDashboardResponse(
        total_users=int(total_users),
        active_users=int(active_users),
        total_bookings=int(total_bookings),
        paid_bookings=int(paid_bookings),
        pending_bookings=int(pending_bookings),
        canceled_bookings=int(canceled_bookings),
        total_revenue=total_revenue_dec,
        revenue_this_month=revenue_month_dec,
        platform_profit=(total_revenue_dec * PROFIT_MARGIN).quantize(Decimal("0.01")),
        total_tickets=int(total_tickets),
        valid_tickets=int(valid_tickets),
        used_tickets=int(used_tickets),
        completed_payments=int(completed_payments),
        pending_payments=int(pending_payments),
        refunded_payments=int(refunded_payments),
        monthly_revenue=monthly_revenue,
        top_routes=top_routes,
        recent_bookings=recent_bookings,
        staff_count=int(staff_count),
    )
    if user is not None and not await user_is_superadmin(db, user):
        return _redact_financial_dashboard(response)
    return response


async def build_revenue_analytics(db: AsyncSession) -> RevenueAnalyticsResponse:
    """Full revenue breakdown for superadmin analytics page."""
    now = datetime.now(UTC)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    total_revenue = (
        await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                Payment.status == "completed",
            ),
        )
    ).scalar_one()
    revenue_this_month = (
        await db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                Payment.status == "completed",
                Payment.created_at >= month_start,
            ),
        )
    ).scalar_one()

    monthly_col = func.to_char(Payment.created_at, "YYYY-MM")
    monthly_rows = (
        await db.execute(
            select(
                monthly_col.label("month"),
                func.coalesce(func.sum(Payment.amount), 0).label("revenue"),
                func.count(Payment.id).label("bookings"),
            )
            .where(Payment.status == "completed")
            .group_by(monthly_col)
            .order_by(monthly_col)
            .limit(12),
        )
    ).all()
    monthly_revenue = [
        MonthlyRevenuePoint(
            month=row.month,
            revenue=Decimal(str(row.revenue)),
            bookings=int(row.bookings),
        )
        for row in monthly_rows
    ]

    route_rows = (
        await db.execute(
            select(
                Flight.origin_iata,
                Flight.destination_iata,
                func.count(Reservation.id).label("bookings"),
                func.coalesce(func.sum(Reservation.total_price), 0).label("revenue"),
            )
            .join(Reservation, Reservation.flight_id == Flight.id)
            .where(Reservation.status == ReservationStatus.PAID.value)
            .group_by(Flight.origin_iata, Flight.destination_iata)
            .order_by(func.count(Reservation.id).desc())
            .limit(10),
        )
    ).all()
    top_routes = [
        RouteStat(
            origin_iata=row.origin_iata,
            destination_iata=row.destination_iata,
            bookings=int(row.bookings),
            revenue=Decimal(str(row.revenue)),
        )
        for row in route_rows
    ]

    payment_rows = (
        await db.execute(
            select(
                Payment.status,
                func.count(Payment.id).label("count"),
                func.coalesce(func.sum(Payment.amount), 0).label("amount"),
            )
            .group_by(Payment.status)
            .order_by(func.count(Payment.id).desc()),
        )
    ).all()
    payment_breakdown = [
        PaymentStatusBreakdown(
            status=row.status,
            count=int(row.count),
            amount=Decimal(str(row.amount)),
        )
        for row in payment_rows
    ]

    return RevenueAnalyticsResponse(
        total_revenue=Decimal(str(total_revenue)),
        revenue_this_month=Decimal(str(revenue_this_month)),
        monthly_revenue=monthly_revenue,
        top_routes=top_routes,
        payment_breakdown=payment_breakdown,
    )


async def _ticket_revenue_totals(db: AsyncSession) -> tuple[Decimal, Decimal]:
    """Sum paid ticket prices (Reservation.total_price) for completed payments."""
    now = datetime.now(UTC)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    ticket_revenue = func.coalesce(Reservation.total_price, 0)
    base = (
        select(func.coalesce(func.sum(ticket_revenue), 0))
        .select_from(Payment)
        .join(Reservation, Payment.reservation_id == Reservation.id)
        .where(Payment.status == "completed")
    )
    total = (await db.execute(base)).scalar_one()
    revenue_this_month = (
        await db.execute(base.where(Payment.created_at >= month_start))
    ).scalar_one()
    return Decimal(str(total)), Decimal(str(revenue_this_month))


async def _monthly_ticket_financials(
    db: AsyncSession,
) -> tuple[list[MonthlyRevenuePoint], list[MonthlyRevenuePoint]]:
    """Monthly ticket revenue and profit (revenue minus 88% cost) from paid bookings."""
    monthly_col = func.to_char(Payment.created_at, "YYYY-MM")
    ticket_revenue = func.coalesce(Reservation.total_price, 0)
    rows = (
        await db.execute(
            select(
                monthly_col.label("month"),
                func.coalesce(func.sum(ticket_revenue), 0).label("revenue"),
                func.count(Payment.id).label("bookings"),
            )
            .select_from(Payment)
            .join(Reservation, Payment.reservation_id == Reservation.id)
            .where(Payment.status == "completed")
            .group_by(monthly_col)
            .order_by(monthly_col)
            .limit(12),
        )
    ).all()
    monthly_revenue: list[MonthlyRevenuePoint] = []
    monthly_profit: list[MonthlyRevenuePoint] = []
    for row in rows:
        revenue_dec = Decimal(str(row.revenue)).quantize(Decimal("0.01"))
        profit_dec = (revenue_dec * PROFIT_MARGIN).quantize(Decimal("0.01"))
        bookings = int(row.bookings)
        monthly_revenue.append(
            MonthlyRevenuePoint(month=row.month, revenue=revenue_dec, bookings=bookings),
        )
        monthly_profit.append(
            MonthlyRevenuePoint(month=row.month, revenue=profit_dec, bookings=bookings),
        )
    return monthly_revenue, monthly_profit


async def build_profit_analytics(db: AsyncSession) -> ProfitAnalyticsResponse:
    """Platform profit breakdown for superadmin analytics page."""
    revenue_data = await build_revenue_analytics(db)
    total_revenue_dec, revenue_month_dec = await _ticket_revenue_totals(db)
    monthly_revenue, monthly_profit = await _monthly_ticket_financials(db)
    return ProfitAnalyticsResponse(
        total_revenue=total_revenue_dec,
        platform_profit=(total_revenue_dec * PROFIT_MARGIN).quantize(Decimal("0.01")),
        revenue_this_month=revenue_month_dec,
        profit_this_month=(revenue_month_dec * PROFIT_MARGIN).quantize(Decimal("0.01")),
        monthly_revenue=monthly_revenue,
        monthly_profit=monthly_profit,
        top_routes=revenue_data.top_routes,
    )


async def list_admin_reservations(
    db: AsyncSession,
    *,
    page: int,
    page_size: int,
) -> tuple[list[AdminReservationRow], int]:
    visible_statuses = [ReservationStatus.PAID.value, ReservationStatus.CANCELED.value]
    total = (
        await db.execute(
            select(func.count()).select_from(Reservation).where(
                Reservation.status.in_(visible_statuses),
            ),
        )
    ).scalar_one()
    offset = (page - 1) * page_size
    result = await db.execute(
        select(Reservation)
        .options(
            selectinload(Reservation.user),
            selectinload(Reservation.flight),
            selectinload(Reservation.ticket),
        )
        .where(Reservation.status.in_(visible_statuses))
        .order_by(Reservation.created_at.desc())
        .offset(offset)
        .limit(page_size),
    )
    rows: list[AdminReservationRow] = []
    for res in result.scalars().all():
        pay_result = await db.execute(
            select(Payment.status)
            .where(Payment.reservation_id == res.id)
            .order_by(Payment.created_at.desc())
            .limit(1),
        )
        payment_status = pay_result.scalar_one_or_none()
        flight = res.flight
        rows.append(
            AdminReservationRow(
                id=res.id,
                user_id=res.user_id,
                user_email=res.user.email if res.user else "unknown",
                seat=res.seat,
                status=_display_booking_status(res.status, payment_status),
                ticket_number=res.ticket.ticket_number if res.ticket else None,
                total_price=res.total_price,
                currency=res.currency,
                created_at=res.created_at.isoformat(),
                flight=AdminReservationFlight(
                    origin_iata=flight.origin_iata,
                    destination_iata=flight.destination_iata,
                    carrier_code=flight.carrier_code,
                    flight_number=flight.flight_number,
                    departure_at=flight.departure_at.isoformat(),
                ) if flight else AdminReservationFlight(
                    origin_iata="—",
                    destination_iata="—",
                    carrier_code="—",
                    flight_number="—",
                    departure_at=now_iso(),
                ),
                payment_status=_display_payment_status(res.status, payment_status),
            ),
        )
    return rows, int(total)


def now_iso() -> str:
    return datetime.now(UTC).isoformat()
