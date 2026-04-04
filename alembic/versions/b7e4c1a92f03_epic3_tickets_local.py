"""Epic 3: local tickets schema (booking_id, qr_code, issued_at, statuses, ticket_images).

Revision ID: b7e4c1a92f03
Revises: 0d52ce81312c
Create Date: 2026-04-02

"""

from collections.abc import Sequence
from datetime import datetime

import sqlalchemy as sa
from alembic import op

revision: str = "b7e4c1a92f03"
down_revision: str | None = "0d52ce81312c"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute('ALTER TABLE tickets RENAME COLUMN reservation_id TO booking_id')
    op.execute("ALTER INDEX ix_tickets_reservation_id RENAME TO ix_tickets_booking_id")
    op.execute("ALTER TABLE tickets RENAME COLUMN qr_payload TO qr_code")
    op.execute("ALTER TABLE tickets RENAME COLUMN created_at TO issued_at")

    op.execute("UPDATE tickets SET status = 'valid' WHERE status = 'issued'")
    op.execute(
        "UPDATE tickets SET status = 'canceled' WHERE status IN ('cancelled', 'refunded')"
    )
    op.execute(
        """UPDATE tickets SET qr_code = ticket_number
           WHERE qr_code LIKE '{%' OR qr_code IS NULL OR qr_code = ''"""
    )

    op.create_table(
        "ticket_images",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("ticket_id", sa.Integer(), nullable=False),
        sa.Column("file_path", sa.String(length=500), nullable=False),
        sa.Column("uploaded_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["ticket_id"], ["tickets.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_ticket_images_id"), "ticket_images", ["id"], unique=False)
    op.create_index(op.f("ix_ticket_images_ticket_id"), "ticket_images", ["ticket_id"], unique=False)

    now = datetime.utcnow()
    conn = op.get_bind()
    perms = [
        ("tickets.download", "Download own ticket PDF"),
        ("tickets.upload", "Upload ticket-related images"),
    ]
    for name, desc in perms:
        conn.execute(
            sa.text(
                """
                INSERT INTO permissions (name, description, created_at)
                VALUES (:name, :description, :created_at)
                ON CONFLICT (name) DO NOTHING
                """,
            ),
            {"name": name, "description": desc, "created_at": now},
        )

    op.execute(
        sa.text(
            """
            INSERT INTO role_permissions (role_id, permission_id, created_at)
            SELECT r.id, p.id, now()
            FROM roles r
            JOIN permissions p ON p.name IN ('tickets.download', 'tickets.upload')
            WHERE r.name = 'user'
            AND NOT EXISTS (
                SELECT 1 FROM role_permissions rp
                WHERE rp.role_id = r.id AND rp.permission_id = p.id
            )
            """,
        ),
    )
    op.execute(
        sa.text(
            """
            INSERT INTO role_permissions (role_id, permission_id, created_at)
            SELECT r.id, p.id, now()
            FROM roles r
            JOIN permissions p ON p.name IN ('tickets.download', 'tickets.upload')
            WHERE r.name = 'admin'
            AND NOT EXISTS (
                SELECT 1 FROM role_permissions rp
                WHERE rp.role_id = r.id AND rp.permission_id = p.id
            )
            """,
        ),
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_ticket_images_ticket_id"), table_name="ticket_images")
    op.drop_index(op.f("ix_ticket_images_id"), table_name="ticket_images")
    op.drop_table("ticket_images")

    conn = op.get_bind()
    conn.execute(sa.text("DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE name IN ('tickets.download', 'tickets.upload'))"))
    conn.execute(sa.text("DELETE FROM permissions WHERE name IN ('tickets.download', 'tickets.upload')"))

    op.execute("UPDATE tickets SET status = 'issued' WHERE status = 'valid'")
    op.execute("UPDATE tickets SET status = 'cancelled' WHERE status = 'canceled'")

    op.execute("ALTER TABLE tickets RENAME COLUMN issued_at TO created_at")
    op.execute("ALTER TABLE tickets RENAME COLUMN qr_code TO qr_payload")
    op.execute("ALTER INDEX ix_tickets_booking_id RENAME TO ix_tickets_reservation_id")
    op.execute("ALTER TABLE tickets RENAME COLUMN booking_id TO reservation_id")
