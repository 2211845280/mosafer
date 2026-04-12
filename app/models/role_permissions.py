"""SQLAlchemy ORM model for role-permission links."""

<<<<<<< HEAD
from datetime import UTC, datetime
=======
from datetime import datetime
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767

from sqlalchemy import DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class RolePermission(Base):
    """Link table between roles and permissions."""

    __tablename__ = "role_permissions"

    role_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("roles.id", ondelete="CASCADE"),
        primary_key=True,
    )
    permission_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("permissions.id", ondelete="CASCADE"),
        primary_key=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
<<<<<<< HEAD
        default=lambda: datetime.now(UTC),
=======
        default=datetime.utcnow,
>>>>>>> 7ebaa1a4f8a62d839050d1eb0b1bdc557cc76767
        nullable=False,
    )
