"""add user phone"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = "20261019_0027"
down_revision: str | None = "20261019_0026"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("phone", sa.String(length=40), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "phone")
