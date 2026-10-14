"""add change for to orders

Revision ID: 20261009_0004
Revises: 20261009_0003
Create Date: 2026-10-09

"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20261009_0004"
down_revision: str | None = "20261009_0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("change_for", sa.Numeric(12, 2), nullable=True))


def downgrade() -> None:
    op.drop_column("orders", "change_for")
