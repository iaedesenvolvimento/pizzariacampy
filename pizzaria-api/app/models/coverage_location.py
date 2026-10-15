from sqlalchemy import Boolean, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import TimestampedModel


class CoverageLocation(TimestampedModel):
    __tablename__ = "coverage_locations"

    city: Mapped[str] = mapped_column(String(120), nullable=False)
    neighborhood: Mapped[str] = mapped_column(String(120), nullable=False)
    aliases: Mapped[str | None] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(String(80), nullable=False, server_default=text("'initial_mapping'"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
