"""force max flavor price for two-flavor offers

Revision ID: 20261017_0020
Revises: 20261016_0019
Create Date: 2026-10-17
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261017_0020"
down_revision: str | None = "20261016_0019"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        sa.text(
            """
            UPDATE pizza_configurations
            SET pricing_rule = 'MAX_FLAVOR_PRICE'
            WHERE flavor_count = 2
            """
        )
    )


def downgrade() -> None:
    pass
