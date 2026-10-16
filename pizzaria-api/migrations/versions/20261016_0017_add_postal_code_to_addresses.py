"""store postal codes for saved customer addresses

Revision ID: 20261016_0017
Revises: 20261015_0016
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261016_0017"
down_revision: str | None = "20261015_0016"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "customer_addresses",
        sa.Column("postal_code", sa.String(length=9), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("customer_addresses", "postal_code")
