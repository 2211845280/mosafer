"""Epic 1 schema and RBAC bootstrap.

Revision ID: 30ebe16a9775
Revises:
Create Date: 2026-03-27 18:55:34.174761
"""

from collections.abc import Sequence
from datetime import datetime

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "30ebe16a9775"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "examples",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_examples_id"), "examples", ["id"], unique=False)

    op.create_table(
        "roles",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_roles_id"), "roles", ["id"], unique=False)
    op.create_index(op.f("ix_roles_name"), "roles", ["name"], unique=True)

    op.create_table(
        "permissions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=150), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_permissions_id"), "permissions", ["id"], unique=False)
    op.create_index(op.f("ix_permissions_name"), "permissions", ["name"], unique=True)

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("full_name", sa.String(length=255), nullable=True),
        sa.Column("password_hash", sa.String(length=255), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("role_id", sa.Integer(), nullable=True),
        sa.Column("avatar_path", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_users_id"), "users", ["id"], unique=False)
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)
    op.alter_column("users", "is_active", server_default=None)

    op.create_table(
        "role_permissions",
        sa.Column("role_id", sa.Integer(), nullable=False),
        sa.Column("permission_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["permission_id"], ["permissions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("role_id", "permission_id"),
    )

    op.create_table(
        "revoked_tokens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("jti", sa.String(length=64), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("logout_hash", sa.String(length=64), nullable=False),
        sa.Column("execute_hash", sa.String(length=64), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_revoked_tokens_id"), "revoked_tokens", ["id"], unique=False)
    op.create_index(op.f("ix_revoked_tokens_jti"), "revoked_tokens", ["jti"], unique=True)
    op.create_index(op.f("ix_revoked_tokens_user_id"), "revoked_tokens", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_revoked_tokens_logout_hash"), "revoked_tokens", ["logout_hash"], unique=True
    )
    op.create_index(
        op.f("ix_revoked_tokens_execute_hash"), "revoked_tokens", ["execute_hash"], unique=True
    )

    now = datetime.utcnow()
    role_table = sa.table(
        "roles",
        sa.column("name", sa.String),
        sa.column("description", sa.String),
        sa.column("created_at", sa.DateTime(timezone=True)),
    )
    permission_table = sa.table(
        "permissions",
        sa.column("name", sa.String),
        sa.column("description", sa.String),
        sa.column("created_at", sa.DateTime(timezone=True)),
    )
    op.bulk_insert(
        role_table,
        [
            {"name": "user", "description": "Default user role", "created_at": now},
            {"name": "admin", "description": "Administrator role", "created_at": now},
        ],
    )
    op.bulk_insert(
        permission_table,
        [
            {"name": "users.profile.read", "description": "Read own profile", "created_at": now},
            {
                "name": "users.profile.update",
                "description": "Update own profile",
                "created_at": now,
            },
            {
                "name": "users.profile.password",
                "description": "Change own password",
                "created_at": now,
            },
            {"name": "users.profile.avatar", "description": "Upload own avatar", "created_at": now},
            {"name": "users.admin.manage", "description": "Manage all users", "created_at": now},
        ],
    )
    op.execute(
        sa.text(
            """
            INSERT INTO role_permissions (role_id, permission_id, created_at)
            SELECT r.id, p.id, now()
            FROM roles r
            JOIN permissions p ON p.name IN (
                'users.profile.read',
                'users.profile.update',
                'users.profile.password',
                'users.profile.avatar'
            )
            WHERE r.name = 'user'
            """,
        ),
    )
    op.execute(
        sa.text(
            """
            INSERT INTO role_permissions (role_id, permission_id, created_at)
            SELECT r.id, p.id, now()
            FROM roles r
            JOIN permissions p ON p.name IN (
                'users.profile.read',
                'users.profile.update',
                'users.profile.password',
                'users.profile.avatar',
                'users.admin.manage'
            )
            WHERE r.name = 'admin'
            """,
        ),
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_revoked_tokens_execute_hash"), table_name="revoked_tokens")
    op.drop_index(op.f("ix_revoked_tokens_logout_hash"), table_name="revoked_tokens")
    op.drop_index(op.f("ix_revoked_tokens_user_id"), table_name="revoked_tokens")
    op.drop_index(op.f("ix_revoked_tokens_jti"), table_name="revoked_tokens")
    op.drop_index(op.f("ix_revoked_tokens_id"), table_name="revoked_tokens")
    op.drop_table("revoked_tokens")
    op.drop_table("role_permissions")
    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_index(op.f("ix_users_id"), table_name="users")
    op.drop_table("users")
    op.drop_index(op.f("ix_permissions_name"), table_name="permissions")
    op.drop_index(op.f("ix_permissions_id"), table_name="permissions")
    op.drop_table("permissions")
    op.drop_index(op.f("ix_roles_name"), table_name="roles")
    op.drop_index(op.f("ix_roles_id"), table_name="roles")
    op.drop_table("roles")
    op.drop_index(op.f("ix_examples_id"), table_name="examples")
    op.drop_table("examples")
