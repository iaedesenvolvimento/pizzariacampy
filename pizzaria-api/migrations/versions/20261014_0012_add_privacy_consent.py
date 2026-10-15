"""record privacy consent on users"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261014_0012"
down_revision: str | None = "20261012_0011"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("privacy_consent_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "privacy_consent_at")
