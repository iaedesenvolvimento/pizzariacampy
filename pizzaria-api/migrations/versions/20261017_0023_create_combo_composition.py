"""create structured combo composition"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "20261017_0023"
down_revision: str | None = "20261017_0022"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "combo_groups",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("combo_size_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("label", sa.String(100), nullable=False),
        sa.Column("required_quantity", sa.Integer(), nullable=False),
        sa.Column("selection_mode", sa.String(20), nullable=False),
        sa.Column("display_order", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.ForeignKeyConstraint(["combo_size_id"], ["product_sizes.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint("required_quantity > 0", name="ck_combo_groups_required_positive"),
        sa.CheckConstraint("selection_mode IN ('CHOICE', 'FIXED')", name="ck_combo_groups_selection_mode"),
    )
    op.create_table(
        "combo_group_options",
        sa.Column("group_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("component_size_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("fixed_quantity", sa.Integer(), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.ForeignKeyConstraint(["group_id"], ["combo_groups.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["component_size_id"], ["product_sizes.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("group_id", "component_size_id"),
        sa.CheckConstraint("fixed_quantity IS NULL OR fixed_quantity >= 0", name="ck_combo_options_fixed_non_negative"),
    )


def downgrade() -> None:
    op.drop_table("combo_group_options")
    op.drop_table("combo_groups")
