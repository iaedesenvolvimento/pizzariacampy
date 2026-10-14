from datetime import time

from sqlalchemy import Boolean, Integer, Time, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import TimestampedModel


class BusinessHours(TimestampedModel):
    __tablename__ = "business_hours"
    __table_args__ = (UniqueConstraint("weekday", name="uq_business_hours_weekday"),)

    weekday: Mapped[int] = mapped_column(Integer, nullable=False)
    open_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    close_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    is_closed: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
