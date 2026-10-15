from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.pricing import PricingItemInput


class CreateOrderRequest(BaseModel):
    items: list[PricingItemInput] = Field(min_length=1)
    fulfillment_type: str = Field(pattern=r"^(DELIVERY|PICKUP)$")
    payment_method: str = Field(pattern=r"^(PIX|CASH|CARD_ON_DELIVERY)$")
    change_for: Decimal | None = Field(default=None, gt=0)
    delivery_address: str | None = Field(default=None, max_length=500)
    delivery_number: str | None = Field(default=None, max_length=20)
    delivery_postal_code: str | None = Field(default=None, max_length=9)
    delivery_neighborhood: str | None = Field(default=None, max_length=120)
    delivery_city: str | None = Field(default=None, max_length=120)
    customer_note: str | None = Field(default=None, max_length=500)
    coupon_code: str | None = Field(default=None, max_length=40)


class OrderItemFlavorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    flavor_id: UUID | None
    flavor_name: str
    position: int
    price_reference: Decimal


class OrderItemExtraResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    extra_id: UUID | None
    extra_name: str
    unit_price: Decimal
    quantity: int
    total_price: Decimal


class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    product_id: UUID | None
    product_name: str
    size_name: str
    edge_name: str | None
    unit_price: Decimal
    quantity: int
    extras_total: Decimal
    line_total: Decimal
    flavors: list[OrderItemFlavorResponse]
    extras: list[OrderItemExtraResponse]


class PaymentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    method: str
    status: str
    amount: Decimal
    proof_url: str | None = None
    reviewed_at: datetime | None = None
    notes: str | None = None


class OrderStatusHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    from_status: str | None
    to_status: str
    reason: str | None


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    order_number: str
    fulfillment_type: str
    status: str
    payment_method: str
    payment_status: str
    subtotal: Decimal
    delivery_fee: Decimal
    discount_amount: Decimal
    total_amount: Decimal
    coupon_code: str | None
    delivery_address_snapshot: dict | None
    customer_note: str | None
    items: list[OrderItemResponse]
    payments: list[PaymentResponse]
    status_history: list[OrderStatusHistoryResponse]


class CancelOrderRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=300)


class UpdateOrderStatusRequest(BaseModel):
    status: str = Field(
        pattern=r"^(CONFIRMED|PREPARING|READY|OUT_FOR_DELIVERY|DELIVERED|CANCELLED)$"
    )
    reason: str | None = Field(default=None, max_length=300)
