from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import TimestampedModel


class StoreSettings(TimestampedModel):
    __tablename__ = "store_settings"

    store_name: Mapped[str] = mapped_column(String(120), nullable=False)
    phone: Mapped[str] = mapped_column(String(40), nullable=False, server_default="")
    address: Mapped[str] = mapped_column(Text, nullable=False, server_default="")
    pix_key: Mapped[str] = mapped_column(String(255), nullable=False, server_default="")
    pickup_instructions: Mapped[str] = mapped_column(Text, nullable=False, server_default="")
