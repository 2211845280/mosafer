"""Mark existing user accounts as email-verified."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "verify_existing_user_emails"
down_revision: str | None = "add_checkout_sessions"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        sa.text(
            """
            UPDATE users
            SET is_email_verified = true
            WHERE is_email_verified = false
            """,
        ),
    )


def downgrade() -> None:
    pass
