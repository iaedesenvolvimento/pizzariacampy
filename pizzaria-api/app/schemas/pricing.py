from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class PricingExtraInput(BaseModel):
    extra_id: UUID
    quantity: int = Field(default=1, ge=1)


class PricingItemInput(BaseModel):
    product_id: UUID
    product_size_id: UUID
    flavor_ids: list[UUID] = Field(default_factory=list, max_length=4)
    edge_id: UUID | None = None
    extras: list[PricingExtraInput] = Field(default_factory=list)
    quantity: int = Field(default=1, ge=1)


class PricingQuoteRequest(BaseModel):
    items: list[PricingItemInput] = Field(min_length=1)
    fulfillment_type: str = Field(pattern=r"^(DELIVERY|PICKUP)$")
    coupon_code: str | None = Field(default=None, max_length=40)


class PricingExtraBreakdown(BaseModel):
    extra_id: UUID
    quantity: int
    unit_price: Decimal
    total_price: Decimal


class PricingItemBreakdown(BaseModel):
    product_id: UUID
    product_size_id: UUID
    flavor_ids: list[UUID]
    base_price: Decimal
    edge_price: Decimal
    extras_total: Decimal
    unit_price: Decimal
    quantity: int
    line_total: Decimal
    extras: list[PricingExtraBreakdown]


class PricingQuoteResponse(BaseModel):
    items: list[PricingItemBreakdown]
    subtotal: Decimal
    delivery_fee: Decimal
    discount_amount: Decimal
    total_amount: Decimal
    coupon_code: str | None = None
