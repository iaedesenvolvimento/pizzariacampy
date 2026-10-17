"""create pizza configurations

Revision ID: 20261016_0018
Revises: 20261016_0017
Create Date: 2026-10-16

"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "20261016_0018"
down_revision: str | None = "20261016_0017"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "pizza_configurations",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_size_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("flavor_count", sa.Integer(), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=False),
        sa.Column("display_order", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.Column(
            "pricing_rule",
            sa.String(30),
            server_default=sa.text("'MAX_FLAVOR_PRICE'"),
            nullable=False,
        ),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["product_size_id"], ["product_sizes.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "product_size_id", "flavor_count", name="uq_pizza_configurations_size_flavor_count"
        ),
        sa.CheckConstraint("flavor_count > 0", name="ck_pizza_configurations_flavor_count_positive"),
        sa.CheckConstraint("display_order >= 0", name="ck_pizza_configurations_display_order_non_negative"),
    )
    op.create_index(
        "ix_pizza_configurations_size_active",
        "pizza_configurations",
        ["product_size_id", "is_active", "display_order"],
    )
    op.execute(
        sa.text(
            """
            INSERT INTO pizza_configurations
                (id, product_size_id, flavor_count, display_name, display_order, pricing_rule)
            SELECT
                gen_random_uuid(),
                ps.id,
                ps.max_flavors,
                ps.name || ' — ' || ps.max_flavors ||
                    CASE WHEN ps.max_flavors = 1 THEN ' sabor' ELSE ' sabores' END,
                0,
                'MAX_FLAVOR_PRICE'
            FROM product_sizes ps
            JOIN products p ON p.id = ps.product_id
            WHERE p.product_type = 'PIZZA'
            """
        )
    )


def downgrade() -> None:
    op.drop_index("ix_pizza_configurations_size_active", table_name="pizza_configurations")
    op.drop_table("pizza_configurations")
