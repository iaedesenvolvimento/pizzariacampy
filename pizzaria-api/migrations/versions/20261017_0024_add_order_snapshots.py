"""add order composition snapshots and idempotency"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20261017_0024"
down_revision: str | None = "20261017_0023"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("customer_name_snapshot", sa.String(120), nullable=True))
    op.add_column("orders", sa.Column("customer_phone_snapshot", sa.String(40), nullable=True))
    op.add_column("orders", sa.Column("source_address_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("orders", sa.Column("delivery_zone_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("orders", sa.Column("coupon_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("orders", sa.Column("coupon_code_snapshot", sa.String(40), nullable=True))
    op.add_column("orders", sa.Column("idempotency_key", sa.String(120), nullable=True))
    op.create_foreign_key("fk_orders_source_address", "orders", "customer_addresses", ["source_address_id"], ["id"], ondelete="SET NULL")
    op.create_foreign_key("fk_orders_delivery_zone", "orders", "delivery_zones", ["delivery_zone_id"], ["id"], ondelete="SET NULL")
    op.create_foreign_key("fk_orders_coupon", "orders", "coupons", ["coupon_id"], ["id"], ondelete="SET NULL")
    op.create_unique_constraint("uq_orders_idempotency_key", "orders", ["idempotency_key"])

    op.add_column("order_items", sa.Column("pizza_configuration_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("order_items", sa.Column("configuration_name_snapshot", sa.String(100), nullable=True))
    op.add_column("order_items", sa.Column("flavor_count_snapshot", sa.Integer(), nullable=True))
    op.add_column("order_items", sa.Column("pricing_rule_snapshot", sa.String(40), nullable=True))
    op.add_column("order_items", sa.Column("parent_item_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("order_items", sa.Column("included_in_parent", sa.Boolean(), server_default=sa.text("false"), nullable=False))
    op.create_foreign_key("fk_order_items_configuration", "order_items", "pizza_configurations", ["pizza_configuration_id"], ["id"], ondelete="SET NULL")
    op.create_foreign_key("fk_order_items_parent", "order_items", "order_items", ["parent_item_id"], ["id"], ondelete="CASCADE")

    op.add_column("order_item_flavors", sa.Column("fraction_numerator", sa.Integer(), nullable=True))
    op.add_column("order_item_flavors", sa.Column("fraction_denominator", sa.Integer(), nullable=True))
    op.add_column("order_item_flavors", sa.Column("reference_price_snapshot", sa.Numeric(12, 2), nullable=True))
    op.add_column("order_item_extras", sa.Column("quantity_per_unit", sa.Integer(), nullable=True))
    op.add_column("order_item_extras", sa.Column("unit_price_snapshot", sa.Numeric(12, 2), nullable=True))
    op.add_column("payments", sa.Column("provider", sa.String(50), nullable=True))
    op.add_column("payments", sa.Column("provider_reference", sa.String(150), nullable=True))
    op.add_column("payments", sa.Column("idempotency_key", sa.String(120), nullable=True))
    op.create_unique_constraint("uq_payments_idempotency_key", "payments", ["idempotency_key"])


def downgrade() -> None:
    op.drop_constraint("uq_payments_idempotency_key", "payments", type_="unique")
    op.drop_column("payments", "idempotency_key")
    op.drop_column("payments", "provider_reference")
    op.drop_column("payments", "provider")
    op.drop_column("order_item_extras", "unit_price_snapshot")
    op.drop_column("order_item_extras", "quantity_per_unit")
    op.drop_column("order_item_flavors", "reference_price_snapshot")
    op.drop_column("order_item_flavors", "fraction_denominator")
    op.drop_column("order_item_flavors", "fraction_numerator")
    op.drop_constraint("fk_order_items_parent", "order_items", type_="foreignkey")
    op.drop_constraint("fk_order_items_configuration", "order_items", type_="foreignkey")
    for column in ("included_in_parent", "parent_item_id", "pricing_rule_snapshot", "flavor_count_snapshot", "configuration_name_snapshot", "pizza_configuration_id"):
        op.drop_column("order_items", column)
    op.drop_constraint("uq_orders_idempotency_key", "orders", type_="unique")
    op.drop_constraint("fk_orders_coupon", "orders", type_="foreignkey")
    op.drop_constraint("fk_orders_delivery_zone", "orders", type_="foreignkey")
    op.drop_constraint("fk_orders_source_address", "orders", type_="foreignkey")
    for column in ("idempotency_key", "coupon_code_snapshot", "coupon_id", "delivery_zone_id", "source_address_id", "customer_phone_snapshot", "customer_name_snapshot"):
        op.drop_column("orders", column)
