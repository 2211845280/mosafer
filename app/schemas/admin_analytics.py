"""Admin dashboard and analytics schemas."""

from decimal import Decimal

from pydantic import BaseModel, Field


class MonthlyRevenuePoint(BaseModel):
    month: str
    revenue: Decimal
    bookings: int


class RouteStat(BaseModel):
    origin_iata: str
    destination_iata: str
    bookings: int
    revenue: Decimal


class RecentBookingRow(BaseModel):
    id: int
    user_email: str
    route: str
    amount: Decimal
    currency: str
    status: str
    payment_status: str | None
    created_at: str


class AdminDashboardResponse(BaseModel):
    total_users: int
    active_users: int
    total_bookings: int
    paid_bookings: int
    pending_bookings: int
    canceled_bookings: int
    total_revenue: Decimal
    revenue_this_month: Decimal
    platform_profit: Decimal
    profit_margin_pct: Decimal = Field(default=Decimal("12.0"))
    total_tickets: int
    valid_tickets: int
    used_tickets: int
    completed_payments: int
    pending_payments: int
    refunded_payments: int
    monthly_revenue: list[MonthlyRevenuePoint]
    top_routes: list[RouteStat]
    recent_bookings: list[RecentBookingRow]
    staff_count: int


class AdminReservationFlight(BaseModel):
    origin_iata: str
    destination_iata: str
    carrier_code: str
    flight_number: str
    departure_at: str


class AdminReservationRow(BaseModel):
    id: int
    user_id: int
    user_email: str
    seat: str
    status: str
    ticket_number: str | None
    total_price: Decimal | None
    currency: str | None
    created_at: str
    flight: AdminReservationFlight
    payment_status: str | None


class PaymentStatusBreakdown(BaseModel):
    status: str
    count: int
    amount: Decimal


class RevenueAnalyticsResponse(BaseModel):
    total_revenue: Decimal
    revenue_this_month: Decimal
    monthly_revenue: list[MonthlyRevenuePoint]
    top_routes: list[RouteStat]
    payment_breakdown: list[PaymentStatusBreakdown]


class ProfitAnalyticsResponse(BaseModel):
    total_revenue: Decimal
    platform_profit: Decimal
    profit_margin_pct: Decimal = Field(default=Decimal("12.0"))
    revenue_this_month: Decimal
    profit_this_month: Decimal
    monthly_revenue: list[MonthlyRevenuePoint]
    monthly_profit: list[MonthlyRevenuePoint]
    top_routes: list[RouteStat]
