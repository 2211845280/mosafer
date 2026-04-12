"""SQLAlchemy ORM model for passengers (role-specific profile)."""

from sqlalchemy import ForeignKey, Integer, String
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
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    passport_image: Mapped[str | None] = mapped_column(String(500), nullable=True)
    account_status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    user = relationship("User", back_populates="passenger")
