"""Seed admin user from environment variables.

Revision ID: 67b9b4b9f61c
Revises: 30ebe16a9775
Create Date: 2026-03-28
"""

import os
from collections.abc import Sequence
from datetime import datetime

import sqlalchemy as sa

from alembic import op
from app.core.security import hash_password

# revision identifiers, used by Alembic.
revision: str = "67b9b4b9f61c"
down_revision: str | None = "30ebe16a9775"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    admin_email = os.getenv("ADMIN_EMAIL")
    admin_password = os.getenv("ADMIN_PASSWORD")
    if not admin_email or not admin_password:
        return

    conn = op.get_bind()
    role_id = conn.execute(
        sa.text("SELECT id FROM roles WHERE name = :role_name"),
        {"role_name": "admin"},
    ).scalar()
    if role_id is None:
        return

    existing_user_id = conn.execute(
        sa.text("SELECT id FROM users WHERE email = :email"),
        {"email": admin_email},
    ).scalar()

    password_hash = hash_password(admin_password)
    if existing_user_id is not None:
        conn.execute(
            sa.text(
                """
                UPDATE users
                SET role_id = :role_id,
                    is_active = true,
                    password_hash = :password_hash
                WHERE id = :user_id
                """,
            ),
            {
                "role_id": role_id,
                "password_hash": password_hash,
                "user_id": existing_user_id,
            },
        )
        return

    conn.execute(
        sa.text(
            """
            INSERT INTO users (email, full_name, password_hash, is_active, role_id, created_at)
            VALUES (:email, :full_name, :password_hash, true, :role_id, :created_at)
            """,
        ),
        {
            "email": admin_email,
            "full_name": "Admin",
            "password_hash": password_hash,
            "role_id": role_id,
            "created_at": datetime.utcnow(),
        },
    )


def downgrade() -> None:
    # Intentionally non-destructive: do not delete user data on downgrade.
    pass
