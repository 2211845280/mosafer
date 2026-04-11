"""SQLAlchemy ORM model for user preferences."""

from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class UserPreference(Base):
    __tablename__ = "user_preferences"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    home_address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    home_lat: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    home_lng: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    preferred_transport: Mapped[str] = mapped_column(
        String(20), default="car", nullable=False
    )
    language: Mapped[str] = mapped_column(String(10), default="en", nullable=False)
    currency: Mapped[str] = mapped_column(String(10), default="USD", nullable=False)
    notification_enabled: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )
