from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class AdminOrderSummary(BaseModel):
    id: str
    order_number: str
    status: str
    fulfillment_type: str
    total_amount: Decimal
    created_at: datetime
    payment_id: str | None = None
    payment_status: str | None = None
    proof_url: str | None = None


class AdminDashboardResponse(BaseModel):
    pending_orders: int
    preparing_orders: int
    ready_orders: int
    active_products: int
    active_categories: int
    active_flavors: int
    active_sizes: int
    active_edges: int
    active_extras: int
    customers: int
    recent_orders: list[AdminOrderSummary]


class AdminCustomerResponse(BaseModel):
    id: str
    name: str
    email: str
    is_active: bool
    created_at: datetime


class StoreSettingsResponse(BaseModel):
    store_name: str
    phone: str
    address: str
    pix_key: str
    pickup_instructions: str


class StoreSettingsUpdate(BaseModel):
    store_name: str
    phone: str = ""
    address: str = ""
    pix_key: str = ""
    pickup_instructions: str = ""


class AdminImageUploadResponse(BaseModel):
    image_url: str
    public_id: str
