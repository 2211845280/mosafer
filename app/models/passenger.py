"""SQLAlchemy ORM model for passengers (role-specific profile)."""

from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Passenger(Base):
    __tablename__ = "passengers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str] = mapped_column(String(32), nullable=False)
    passport_image: Mapped[str] = mapped_column(String(500), nullable=False)
    account_status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")
    passport_given_name: Mapped[str | None] = mapped_column(String(80), nullable=True)
    passport_family_name: Mapped[str | None] = mapped_column(String(80), nullable=True)
    passport_date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    passport_gender: Mapped[str | None] = mapped_column(String(1), nullable=True)
    passport_nationality: Mapped[str | None] = mapped_column(String(3), nullable=True)
    passport_number: Mapped[str | None] = mapped_column(String(32), nullable=True)
    passport_expiry: Mapped[date | None] = mapped_column(Date, nullable=True)
    passport_issuing_country: Mapped[str | None] = mapped_column(String(3), nullable=True)
    passport_details_extracted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    user = relationship("User", back_populates="passenger")
