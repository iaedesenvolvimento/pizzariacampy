"""add mercado pago payment fields"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = "20261019_0028"
down_revision: str | None = "20261019_0027"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {column["name"] for column in inspector.get_columns("payments")}
    indexes = {index["name"] for index in inspector.get_indexes("payments")}
    if "provider" not in columns:
        op.add_column("payments", sa.Column("provider", sa.String(length=40), nullable=True))
    if "external_id" not in columns:
        op.add_column("payments", sa.Column("external_id", sa.String(length=120), nullable=True))
    if "ix_payments_external_id" not in indexes:
        op.create_index("ix_payments_external_id", "payments", ["external_id"])
    if "qr_code" not in columns:
        op.add_column("payments", sa.Column("qr_code", sa.Text(), nullable=True))
    if "qr_code_base64" not in columns:
        op.add_column("payments", sa.Column("qr_code_base64", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("payments", "qr_code_base64")
    op.drop_column("payments", "qr_code")
    op.drop_index("ix_payments_external_id", table_name="payments")
    op.drop_column("payments", "external_id")
    op.drop_column("payments", "provider")
