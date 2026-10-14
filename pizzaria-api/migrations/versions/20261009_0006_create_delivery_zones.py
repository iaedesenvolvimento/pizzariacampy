"""create delivery zones

Revision ID: 20261009_0006
Revises: 20261009_0005
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "20261009_0006"
down_revision: str | None = "20261009_0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "delivery_zones",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("city", sa.String(120), nullable=False),
        sa.Column("neighborhood", sa.String(120), nullable=False),
        sa.Column("delivery_fee", sa.Numeric(12, 2), nullable=False),
        sa.Column("minimum_order_amount", sa.Numeric(12, 2), server_default=sa.text("0"), nullable=False),
        sa.Column("estimated_minutes", sa.Integer(), server_default=sa.text("45"), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint("delivery_fee >= 0 AND minimum_order_amount >= 0", name="ck_delivery_zones_amounts"),
    )
    op.create_index("ix_delivery_zones_neighborhood", "delivery_zones", ["neighborhood"])


def downgrade() -> None:
    op.drop_index("ix_delivery_zones_neighborhood", table_name="delivery_zones")
    op.drop_table("delivery_zones")
