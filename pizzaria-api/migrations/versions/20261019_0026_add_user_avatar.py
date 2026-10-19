"""add user avatar"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = "20261019_0026"
down_revision: str | None = "20261017_0025"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("avatar_url", sa.String(length=2048), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "avatar_url")
