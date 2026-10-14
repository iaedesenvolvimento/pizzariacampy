from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class DeliveryZoneRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    city: str = Field(min_length=1, max_length=120)
    neighborhood: str = Field(min_length=1, max_length=120)
    delivery_fee: Decimal = Field(ge=0)
    minimum_order_amount: Decimal = Field(default=0, ge=0)
    estimated_minutes: int = Field(default=45, ge=1, le=300)
    is_active: bool = True


class DeliveryZoneResponse(DeliveryZoneRequest):
    id: UUID


class DeliveryZoneQuoteResponse(BaseModel):
    zone_id: UUID
    zone_name: str
    delivery_fee: Decimal
    minimum_order_amount: Decimal
    estimated_minutes: int
