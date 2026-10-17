"""create size-specific crust and addon pricing"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20261017_0022"
down_revision: str | None = "20261017_0021"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _option_table(name: str) -> None:
    op.create_table(
        name,
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )


def _price_table(name: str, option_table: str, price_column: str) -> None:
    op.create_table(
        name,
        sa.Column("product_size_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(f"{option_table[:-1]}_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(price_column, sa.Numeric(12, 2), nullable=False),
        sa.Column("max_quantity", sa.Integer(), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.ForeignKeyConstraint(["product_size_id"], ["product_sizes.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint([f"{option_table[:-1]}_id"], [f"{option_table}.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("product_size_id", f"{option_table[:-1]}_id"),
        sa.CheckConstraint(f"{price_column} >= 0", name=f"ck_{name}_{price_column}_non_negative"),
    )


def upgrade() -> None:
    _option_table("crusts")
    _option_table("addons")
    _price_table("crust_prices", "crusts", "price")
    _price_table("addon_prices", "addons", "unit_price")


def downgrade() -> None:
    op.drop_table("addon_prices")
    op.drop_table("crust_prices")
    op.drop_table("addons")
    op.drop_table("crusts")
