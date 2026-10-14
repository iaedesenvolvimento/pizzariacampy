from decimal import Decimal

from sqlalchemy import Boolean, Numeric, String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import TimestampedModel


class DeliveryZone(TimestampedModel):
    __tablename__ = "delivery_zones"

    name: Mapped[str] = mapped_column(String(120), nullable=False)
    city: Mapped[str] = mapped_column(String(120), nullable=False)
    neighborhood: Mapped[str] = mapped_column(String(120), nullable=False, index=True)
    delivery_fee: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    minimum_order_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, server_default=text("0"))
    estimated_minutes: Mapped[int] = mapped_column(nullable=False, server_default=text("45"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
