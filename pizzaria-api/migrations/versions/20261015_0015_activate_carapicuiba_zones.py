"""activate all initial Carapicuiba delivery zones

Revision ID: 20261015_0015
Revises: 20261015_0014
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261015_0015"
down_revision: str | None = "20261015_0014"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        sa.text(
            """
            UPDATE coverage_locations
            SET is_active = true, updated_at = now()
            WHERE lower(city) = lower('Carapicuíba')
            """
        )
    )
    op.execute(
        sa.text(
            """
            UPDATE delivery_zones
            SET is_active = true, updated_at = now()
            WHERE lower(city) = lower('Carapicuíba')
            """
        )
    )


def downgrade() -> None:
    op.execute(
        sa.text(
            """
            UPDATE delivery_zones
            SET is_active = false, updated_at = now()
            WHERE lower(city) = lower('Carapicuíba')
              AND delivery_fee = 0
              AND minimum_order_amount = 0
              AND estimated_minutes = 45
            """
        )
    )
    op.execute(
        sa.text(
            """
            UPDATE coverage_locations
            SET is_active = false, updated_at = now()
            WHERE lower(city) = lower('Carapicuíba')
            """
        )
    )
