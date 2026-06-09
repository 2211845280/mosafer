"""Add extracted passport detail columns to passengers table."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "add_passenger_passport_details"
down_revision: str | None = "add_password_reset_fields"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "passengers",
        sa.Column("passport_given_name", sa.String(length=80), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_family_name", sa.String(length=80), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_date_of_birth", sa.Date(), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_gender", sa.String(length=1), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_nationality", sa.String(length=3), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_number", sa.String(length=32), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_expiry", sa.Date(), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_issuing_country", sa.String(length=3), nullable=True),
    )
    op.add_column(
        "passengers",
        sa.Column("passport_details_extracted_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("passengers", "passport_details_extracted_at")
    op.drop_column("passengers", "passport_issuing_country")
    op.drop_column("passengers", "passport_expiry")
    op.drop_column("passengers", "passport_number")
    op.drop_column("passengers", "passport_nationality")
    op.drop_column("passengers", "passport_gender")
    op.drop_column("passengers", "passport_date_of_birth")
    op.drop_column("passengers", "passport_family_name")
    op.drop_column("passengers", "passport_given_name")
