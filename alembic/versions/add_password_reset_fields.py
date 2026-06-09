"""Add password reset fields to users table."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_password_reset_fields"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("password_reset_token_hash", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "users",
        sa.Column("password_reset_expires_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        op.f("ix_users_password_reset_token_hash"),
        "users",
        ["password_reset_token_hash"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_users_password_reset_token_hash"), table_name="users")
    op.drop_column("users", "password_reset_expires_at")
    op.drop_column("users", "password_reset_token_hash")
