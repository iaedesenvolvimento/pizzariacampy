from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class CouponRequest(BaseModel):
    code: str = Field(min_length=3, max_length=40)
    discount_type: str = Field(pattern=r"^(FIXED|PERCENTAGE)$")
    value: Decimal = Field(gt=0)
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    minimum_order_amount: Decimal = Field(default=0, ge=0)
    usage_limit: int | None = Field(default=None, ge=1)
    per_customer_limit: int | None = Field(default=None, ge=1)
    is_active: bool = True
    description: str | None = Field(default=None, max_length=500)


class CouponResponse(CouponRequest):
    id: UUID
    usage_count: int
