"""add normalized catalog links and version columns

The legacy catalog remains readable during the transition. New imports populate
the explicit product/flavor relationship and use ``fixed_price`` when present.
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20261017_0021"
down_revision: str | None = "20261017_0020"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("products", sa.Column("version", sa.Integer(), server_default=sa.text("1"), nullable=False))
    op.add_column("flavors", sa.Column("version", sa.Integer(), server_default=sa.text("1"), nullable=False))
    op.add_column("product_sizes", sa.Column("fixed_price", sa.Numeric(12, 2), nullable=True))
    op.execute(sa.text("UPDATE product_sizes SET fixed_price = price WHERE fixed_price IS NULL"))
    op.alter_column("product_sizes", "price", existing_type=sa.Numeric(12, 2), nullable=True)
    op.create_check_constraint("ck_product_sizes_fixed_price_non_negative", "product_sizes", "fixed_price IS NULL OR fixed_price >= 0")

    op.create_table(
        "product_flavors",
        sa.Column("product_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("flavor_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["flavor_id"], ["flavors.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("product_id", "flavor_id"),
    )
    op.create_index("ix_product_flavors_flavor_id", "product_flavors", ["flavor_id"])

    op.add_column("flavor_size_prices", sa.Column("product_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(
        "fk_flavor_size_prices_product_id", "flavor_size_prices", "products", ["product_id"], ["id"], ondelete="RESTRICT"
    )
    op.create_unique_constraint(
        "uq_flavor_size_price_product_flavor_size", "flavor_size_prices", ["product_id", "flavor_id", "product_size_id"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_flavor_size_price_product_flavor_size", "flavor_size_prices", type_="unique")
    op.drop_constraint("fk_flavor_size_prices_product_id", "flavor_size_prices", type_="foreignkey")
    op.drop_column("flavor_size_prices", "product_id")
    op.drop_index("ix_product_flavors_flavor_id", table_name="product_flavors")
    op.drop_table("product_flavors")
    op.drop_constraint("ck_product_sizes_fixed_price_non_negative", "product_sizes", type_="check")
    op.alter_column("product_sizes", "price", existing_type=sa.Numeric(12, 2), nullable=False)
    op.drop_column("product_sizes", "fixed_price")
    op.drop_column("flavors", "version")
    op.drop_column("products", "version")
