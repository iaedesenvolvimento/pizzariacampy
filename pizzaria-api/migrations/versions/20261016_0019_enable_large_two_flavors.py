"""enable two-flavor offers for large pizzas

Revision ID: 20261016_0019
Revises: 20261016_0018
Create Date: 2026-10-16
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261016_0019"
down_revision: str | None = "20261016_0018"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        sa.text(
            """
            UPDATE product_sizes AS ps
            SET max_flavors = 2
            FROM products AS p
            WHERE p.id = ps.product_id
              AND p.product_type = 'PIZZA'
              AND LOWER(ps.name) = 'grande'
              AND ps.max_flavors < 2
            """
        )
    )
    op.execute(
        sa.text(
            """
            INSERT INTO pizza_configurations
                (id, product_size_id, flavor_count, display_name, display_order, pricing_rule, is_active)
            SELECT
                gen_random_uuid(),
                ps.id,
                2,
                ps.name || ' — 2 sabores',
                1,
                'MAX_FLAVOR_PRICE',
                true
            FROM product_sizes AS ps
            JOIN products AS p ON p.id = ps.product_id
            WHERE p.product_type = 'PIZZA'
              AND LOWER(ps.name) = 'grande'
              AND ps.is_active = true
              AND NOT EXISTS (
                  SELECT 1
                  FROM pizza_configurations AS pc
                  WHERE pc.product_size_id = ps.id
                    AND pc.flavor_count = 2
              )
            """
        )
    )


def downgrade() -> None:
    op.execute(
        sa.text(
            """
            DELETE FROM pizza_configurations AS pc
            USING product_sizes AS ps, products AS p
            WHERE pc.product_size_id = ps.id
              AND ps.product_id = p.id
              AND p.product_type = 'PIZZA'
              AND LOWER(ps.name) = 'grande'
              AND pc.flavor_count = 2
            """
        )
    )
