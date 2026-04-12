"""SQLAlchemy ORM model for users."""

from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
<<<<<<< HEAD
from sqlalchemy.orm import Mapped, mapped_column, relationship
=======
from sqlalchemy.orm import Mapped, mapped_column
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

from app.db.database import Base


class User(Base):
    """Base user model — authentication and identity only.

    Role-specific profile data lives in Passenger / Admin tables
    linked via one-to-one relationships.
    """

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
<<<<<<< HEAD
=======
    full_name: Mapped[str] = mapped_column(String(255), nullable=True)
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    role_id: Mapped[int | None] = mapped_column(
        Integer,
        ForeignKey("roles.id", ondelete="SET NULL"),
        nullable=True,
    )
    avatar_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
<<<<<<< HEAD
    is_email_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    email_verification_token: Mapped[str | None] = mapped_column(
        String(64), unique=True, nullable=True
    )
=======
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    last_login: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    passenger = relationship("Passenger", back_populates="user", uselist=False)
    admin = relationship("Admin", back_populates="user", uselist=False)
