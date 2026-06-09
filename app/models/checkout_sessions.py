"""Temporary checkout sessions before payment completes."""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class CheckoutSessionStatus(StrEnum):
    OPEN = "open"
    CONSUMED = "consumed"
    EXPIRED = "expired"


class CheckoutSession(Base):
    __tablename__ = "checkout_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    flight_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("flights.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    seats: Mapped[list] = mapped_column(JSON, nullable=False)
    adults_count: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    cabin_class: Mapped[str | None] = mapped_column(String(32), nullable=True)
    total_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    currency: Mapped[str | None] = mapped_column(String(3), nullable=True)
    passengers_json: Mapped[list | None] = mapped_column(JSON, nullable=True)
    status: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        default=CheckoutSessionStatus.OPEN.value,
    )
    reservation_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("reservations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )

    user = relationship("User")
    flight = relationship("Flight")
    reservation = relationship("Reservation")
