"""Add bilingual display fields to trip_todos."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_trip_todo_bilingual_fields"
down_revision: str | None = "verify_existing_user_emails"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "trip_todos",
        sa.Column("source_key", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "trip_todos",
        sa.Column("title_ar", sa.String(length=255), nullable=True),
    )
    op.add_column(
        "trip_todos",
        sa.Column("title_en", sa.String(length=255), nullable=True),
    )
    op.create_index("ix_trip_todos_source_key", "trip_todos", ["source_key"])


def downgrade() -> None:
    op.drop_index("ix_trip_todos_source_key", table_name="trip_todos")
    op.drop_column("trip_todos", "title_en")
    op.drop_column("trip_todos", "title_ar")
    op.drop_column("trip_todos", "source_key")
