"""add store timezone and accepting-orders flag"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20261017_0025"
down_revision: str | None = "20261017_0024"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("store_settings", sa.Column("timezone", sa.String(64), server_default=sa.text("'America/Sao_Paulo'"), nullable=False))
    op.add_column("store_settings", sa.Column("accepting_orders", sa.Boolean(), server_default=sa.text("true"), nullable=False))


def downgrade() -> None:
    op.drop_column("store_settings", "accepting_orders")
    op.drop_column("store_settings", "timezone")
