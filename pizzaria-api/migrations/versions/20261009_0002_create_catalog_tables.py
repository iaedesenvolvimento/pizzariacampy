"""create catalog tables

Revision ID: 20261009_0002
Revises: 20261009_0001
Create Date: 2026-10-09

"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "20261009_0002"
down_revision: str | None = "20261009_0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def uuid_column() -> sa.Column:
    return sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False)


def timestamps() -> list[sa.Column]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    ]


def active_column() -> sa.Column:
    return sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False)


def upgrade() -> None:
    op.create_table(
        "categories",
        uuid_column(),
        sa.Column("name", sa.String(80), nullable=False),
        sa.Column("slug", sa.String(100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("sort_order", sa.Integer(), server_default=sa.text("0"), nullable=False),
        active_column(),
        *timestamps(),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index("ix_categories_slug", "categories", ["slug"], unique=True)

    op.create_table(
        "products",
        uuid_column(),
        sa.Column("category_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("slug", sa.String(140), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("product_type", sa.String(20), nullable=False),
        sa.Column("image_url", sa.Text(), nullable=True),
        sa.Column("sort_order", sa.Integer(), server_default=sa.text("0"), nullable=False),
        active_column(),
        *timestamps(),
        sa.ForeignKeyConstraint(["category_id"], ["categories.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index("ix_products_slug", "products", ["slug"], unique=True)
    op.create_index("ix_products_category_active", "products", ["category_id", "is_active"])

    op.create_table(
        "product_sizes",
        uuid_column(),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(60), nullable=False),
        sa.Column("slug", sa.String(80), nullable=False),
        sa.Column("price", sa.Numeric(12, 2), nullable=False),
        sa.Column("slices", sa.Integer(), server_default=sa.text("8"), nullable=False),
        sa.Column("max_flavors", sa.Integer(), nullable=False),
        active_column(),
        *timestamps(),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("product_id", "slug", name="uq_product_sizes_product_slug"),
        sa.CheckConstraint("price >= 0", name="ck_product_sizes_price_non_negative"),
        sa.CheckConstraint("slices > 0", name="ck_product_sizes_slices_positive"),
        sa.CheckConstraint("max_flavors > 0", name="ck_product_sizes_max_flavors_positive"),
    )

    op.create_table(
        "flavors",
        uuid_column(),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("image_url", sa.Text(), nullable=True),
        active_column(),
        *timestamps(),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "flavor_size_prices",
        uuid_column(),
        sa.Column("flavor_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_size_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("price", sa.Numeric(12, 2), nullable=False),
        *timestamps(),
        sa.ForeignKeyConstraint(["flavor_id"], ["flavors.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["product_size_id"], ["product_sizes.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("flavor_id", "product_size_id", name="uq_flavor_size_price"),
        sa.CheckConstraint("price >= 0", name="ck_flavor_size_prices_non_negative"),
    )

    for table_name in ("edges", "extras"):
        op.create_table(
            table_name,
            uuid_column(),
            sa.Column("name", sa.String(100), nullable=False),
            sa.Column("price", sa.Numeric(12, 2), nullable=False),
            active_column(),
            *timestamps(),
            sa.PrimaryKeyConstraint("id"),
            sa.CheckConstraint("price >= 0", name=f"ck_{table_name}_price_non_negative"),
        )


def downgrade() -> None:
    op.drop_table("flavor_size_prices")
    op.drop_table("flavors")
    op.drop_table("product_sizes")
    op.drop_index("ix_products_category_active", table_name="products")
    op.drop_index("ix_products_slug", table_name="products")
    op.drop_table("products")
    op.drop_index("ix_categories_slug", table_name="categories")
    op.drop_table("categories")
    op.drop_table("extras")
    op.drop_table("edges")
