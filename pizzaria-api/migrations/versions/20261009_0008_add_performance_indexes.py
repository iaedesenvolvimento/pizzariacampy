"""add performance indexes

Revision ID: 20261009_0008
Revises: 20261009_0007
"""
from collections.abc import Sequence

from alembic import op


revision: str = "20261009_0008"
down_revision: str | None = "20261009_0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_index("ix_orders_user_created_at", "orders", ["user_id", "created_at"])
    op.create_index("ix_orders_status_created_at", "orders", ["status", "created_at"])
    op.create_index("ix_products_category_sort", "products", ["category_id", "sort_order", "name"])
    op.create_index("ix_delivery_zones_city_neighborhood_active", "delivery_zones", ["city", "neighborhood", "is_active"])
    op.create_index("ix_coupon_redemptions_coupon_user", "coupon_redemptions", ["coupon_id", "user_id"])


def downgrade() -> None:
    op.drop_index("ix_coupon_redemptions_coupon_user", table_name="coupon_redemptions")
    op.drop_index("ix_delivery_zones_city_neighborhood_active", table_name="delivery_zones")
    op.drop_index("ix_products_category_sort", table_name="products")
    op.drop_index("ix_orders_status_created_at", table_name="orders")
    op.drop_index("ix_orders_user_created_at", table_name="orders")
