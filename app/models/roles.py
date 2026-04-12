"""SQLAlchemy ORM model for roles."""

<<<<<<< HEAD
from datetime import UTC, datetime
=======
from datetime import datetime
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class Role(Base):
    """RBAC role model."""

    __tablename__ = "roles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
<<<<<<< HEAD
        default=lambda: datetime.now(UTC),
=======
        default=datetime.utcnow,
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
        nullable=False,
    )
