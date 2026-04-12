"""Add passengers and admins tables, move full_name, add last_login.

Revision ID: a1b2c3d4e5f6
Revises: 3d07861e4485
Create Date: 2026-04-07 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "3d07861e4485"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "passengers",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(32), nullable=True),
        sa.Column("passport_image", sa.String(500), nullable=True),
        sa.Column("account_status", sa.String(32), nullable=False, server_default="active"),
    )
    op.create_index("ix_passengers_id", "passengers", ["id"])
    op.create_index("ix_passengers_user_id", "passengers", ["user_id"])

    op.create_table(
        "admins",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(32), nullable=True),
    )
    op.create_index("ix_admins_id", "admins", ["id"])
    op.create_index("ix_admins_user_id", "admins", ["user_id"])

    op.execute(
        sa.text("""
            INSERT INTO passengers (user_id, full_name)
            SELECT u.id, COALESCE(u.full_name, '')
            FROM users u
            LEFT JOIN roles r ON u.role_id = r.id
            WHERE r.name IS NULL OR r.name != 'admin'
        """)
    )

    op.execute(
        sa.text("""
            INSERT INTO admins (user_id, full_name)
            SELECT u.id, COALESCE(u.full_name, '')
            FROM users u
            JOIN roles r ON u.role_id = r.id
            WHERE r.name = 'admin'
        """)
    )

    op.drop_column("users", "full_name")

    op.add_column(
        "users",
        sa.Column("last_login", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "last_login")

    op.add_column(
        "users",
        sa.Column("full_name", sa.String(255), nullable=True),
    )

    op.execute(
        sa.text("""
            UPDATE users SET full_name = p.full_name
            FROM passengers p
            WHERE users.id = p.user_id
        """)
    )
    op.execute(
        sa.text("""
            UPDATE users SET full_name = a.full_name
            FROM admins a
            WHERE users.id = a.user_id
        """)
    )

    op.drop_table("admins")
    op.drop_table("passengers")
