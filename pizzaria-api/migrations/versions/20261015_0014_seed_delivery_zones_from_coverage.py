"""seed delivery zones from coverage locations

Revision ID: 20261015_0014
Revises: 20261015_0013
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261015_0014"
down_revision: str | None = "20261015_0013"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        sa.text(
            """
            INSERT INTO delivery_zones
                (id, name, city, neighborhood, delivery_fee,
                 minimum_order_amount, estimated_minutes, is_active,
                 created_at, updated_at)
            SELECT
                md5(cl.city || ':' || cl.neighborhood)::uuid,
                cl.city || ' - ' || cl.neighborhood,
                cl.city,
                cl.neighborhood,
                0,
                0,
                45,
                false,
                now(),
                now()
            FROM coverage_locations cl
            WHERE NOT EXISTS (
                SELECT 1
                FROM delivery_zones dz
                WHERE lower(dz.city) = lower(cl.city)
                  AND lower(dz.neighborhood) = lower(cl.neighborhood)
            )
            """
        )
    )


def downgrade() -> None:
    op.execute(
        sa.text(
            """
            DELETE FROM delivery_zones
            WHERE is_active = false
              AND delivery_fee = 0
              AND minimum_order_amount = 0
              AND estimated_minutes = 45
              AND name = city || ' - ' || neighborhood
            """
        )
    )
