from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class FinancePaymentMethodSummary(BaseModel):
    method: str
    order_count: int
    amount: Decimal


class FinanceSummaryResponse(BaseModel):
    start_date: date
    end_date: date
    timezone: str
    sales_definition: str
    gross_sales: Decimal
    orders_count: int
    average_ticket: Decimal
    discounts_total: Decimal
    delivery_fees_total: Decimal
    cancelled_orders_count: int
    cancelled_amount: Decimal
    pix_pending_count: int
    pix_awaiting_proof_count: int
    pix_awaiting_review_count: int
    payment_methods: list[FinancePaymentMethodSummary]


class FinancePaymentMethodsResponse(BaseModel):
    items: list[FinancePaymentMethodSummary]
    start_date: date
    end_date: date
    timezone: str


class FinanceSaleItem(BaseModel):
    order_id: str
    order_number: str
    created_at: datetime
    subtotal: Decimal
    discount_amount: Decimal
    delivery_fee: Decimal
    total_amount: Decimal
    payment_method: str
    payment_status: str
    order_status: str


class FinanceSalesResponse(BaseModel):
    items: list[FinanceSaleItem]
    total: int
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)
    start_date: date
    end_date: date
    timezone: str


class FinancePixPendingItem(BaseModel):
    order_id: str
    order_number: str
    created_at: datetime
    total_amount: Decimal
    payment_status: str
    order_status: str
    proof_url: str | None = None


class FinancePixPendingResponse(BaseModel):
    items: list[FinancePixPendingItem]
    total: int
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)
    start_date: date
    end_date: date
    timezone: str


class FinanceCancellationItem(BaseModel):
    order_id: str
    order_number: str
    created_at: datetime
    total_amount: Decimal
    payment_method: str
    payment_status: str
    order_status: str
    cancelled_reason: str | None = None
    payment_confirmed: bool


class FinanceCancellationsResponse(BaseModel):
    items: list[FinanceCancellationItem]
    total: int
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)
    start_date: date
    end_date: date
    timezone: str
