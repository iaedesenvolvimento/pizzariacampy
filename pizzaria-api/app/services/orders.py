from datetime import UTC, datetime
from decimal import Decimal
from secrets import token_hex
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.catalog import Edge, Extra, Flavor, Product, ProductSize
from app.models.coupon import CouponRedemption
from app.services.delivery import resolve_zone
from app.models.order import (
    Order,
    OrderItem,
    OrderItemExtra,
    OrderItemFlavor,
    OrderStatusHistory,
    Payment,
)
from app.schemas.orders import CreateOrderRequest
from app.schemas.pricing import PricingQuoteRequest
from app.services.pricing import PricingError, calculate_quote, get_flavor_prices
from app.services.coupons import CouponError, calculate_coupon_discount


ORDER_TRANSITIONS: dict[str, set[str]] = {
    "PENDING": {"CONFIRMED", "CANCELLED"},
    "CONFIRMED": {"PREPARING", "CANCELLED"},
    "PREPARING": {"READY", "CANCELLED"},
    "READY": {"OUT_FOR_DELIVERY", "DELIVERED"},
    "OUT_FOR_DELIVERY": {"DELIVERED"},
    "DELIVERED": set(),
    "CANCELLED": set(),
}


class OrderError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def generate_order_number() -> str:
    date_part = datetime.now(UTC).strftime("%Y%m%d")
    return f"CAMPY-{date_part}-{token_hex(3).upper()}"


async def create_order(
    session: AsyncSession,
    user_id: UUID,
    request: CreateOrderRequest,
) -> Order:
    zone = None
    if request.fulfillment_type == "DELIVERY":
        if not request.delivery_address:
            raise OrderError("DELIVERY_ADDRESS_REQUIRED", "Delivery address is required")
        zone = await resolve_zone(session, request.delivery_neighborhood, request.delivery_city)
        if zone is None:
            raise OrderError("DELIVERY_ZONE_NOT_FOUND", "Delivery address is outside the service area")
    if request.payment_method == "CASH" and request.change_for is not None:
        if request.change_for < 0:
            raise OrderError("INVALID_CHANGE_FOR", "Change amount cannot be negative")
    elif request.payment_method != "CASH" and request.change_for is not None:
        raise OrderError("INVALID_CHANGE_FOR", "Change is only valid for cash payments")

    quote_request = PricingQuoteRequest(
        items=request.items,
        fulfillment_type=request.fulfillment_type,
        coupon_code=request.coupon_code,
    )
    try:
        quote = await calculate_quote(session, quote_request, zone.delivery_fee if zone else Decimal("0"), user_id)
    except PricingError as error:
        raise OrderError(error.code, error.message) from error
    if zone and quote.subtotal < zone.minimum_order_amount:
        raise OrderError("MINIMUM_ORDER_NOT_REACHED", f"Delivery minimum is {zone.minimum_order_amount}")
    coupon = None
    if request.coupon_code:
        try:
            _, coupon = await calculate_coupon_discount(session, request.coupon_code, quote.subtotal, user_id)
        except CouponError as error:
            raise OrderError(error.code, error.message) from error

    order = Order(
        order_number=generate_order_number(),
        user_id=user_id,
        fulfillment_type=request.fulfillment_type,
        status="PENDING",
        payment_method=request.payment_method,
        payment_status="PENDING",
        subtotal=quote.subtotal,
        delivery_fee=quote.delivery_fee,
        discount_amount=quote.discount_amount,
        total_amount=quote.total_amount,
        coupon_code=coupon.code if coupon else None,
        change_for=request.change_for,
        customer_note=request.customer_note,
        delivery_address_snapshot={
            "address": request.delivery_address,
            "neighborhood": request.delivery_neighborhood,
            "city": request.delivery_city,
            "zone_name": zone.name,
        } if zone else None,
    )
    session.add(order)
    await session.flush()
    if coupon is not None:
        coupon.usage_count += 1
        session.add(CouponRedemption(coupon_id=coupon.id, user_id=user_id, order_id=order.id))

    for item_input, item_quote in zip(request.items, quote.items, strict=True):
        product = await session.get(Product, item_input.product_id)
        size = await session.get(ProductSize, item_input.product_size_id)
        edge = await session.get(Edge, item_input.edge_id) if item_input.edge_id else None
        if product is None or size is None:
            raise OrderError("CATALOG_CHANGED", "Catalog changed while creating the order")

        order_item = OrderItem(
            order_id=order.id,
            product_id=product.id,
            product_name=product.name,
            product_size_id=size.id,
            size_name=size.name,
            edge_id=edge.id if edge else None,
            edge_name=edge.name if edge else None,
            unit_price=item_quote.unit_price,
            quantity=item_input.quantity,
            extras_total=item_quote.extras_total,
            line_total=item_quote.line_total,
        )
        session.add(order_item)
        await session.flush()

        flavor_prices = await get_flavor_prices(session, size.id, item_input.flavor_ids) if item_input.flavor_ids else {}
        flavors = list(
            await session.scalars(select(Flavor).where(Flavor.id.in_(item_input.flavor_ids)))
        ) if item_input.flavor_ids else []
        flavor_by_id = {flavor.id: flavor for flavor in flavors}
        for position, flavor_id in enumerate(item_input.flavor_ids, start=1):
            flavor = flavor_by_id[flavor_id]
            session.add(
                OrderItemFlavor(
                    order_item_id=order_item.id,
                    flavor_id=flavor.id,
                    flavor_name=flavor.name,
                    position=position,
                    price_reference=flavor_prices[flavor.id],
                )
            )

        for extra_input, extra_quote in zip(item_input.extras, item_quote.extras, strict=True):
            extra = await session.get(Extra, extra_input.extra_id)
            if extra is None:
                raise OrderError("CATALOG_CHANGED", "Catalog changed while creating the order")
            session.add(
                OrderItemExtra(
                    order_item_id=order_item.id,
                    extra_id=extra.id,
                    extra_name=extra.name,
                    unit_price=extra_quote.unit_price,
                    quantity=extra_quote.quantity,
                    total_price=extra_quote.total_price,
                )
            )

    session.add(
        Payment(
            order_id=order.id,
            method=request.payment_method,
            status="PENDING",
            amount=quote.total_amount,
        )
    )
    session.add(
        OrderStatusHistory(
            order_id=order.id,
            from_status=None,
            to_status="PENDING",
            reason="Order created",
        )
    )
    await session.commit()
    return await get_order(session, order.id, user_id)


async def get_order(session: AsyncSession, order_id: UUID, user_id: UUID | None = None) -> Order:
    statement = (
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.flavors),
            selectinload(Order.items).selectinload(OrderItem.extras),
            selectinload(Order.payments),
            selectinload(Order.status_history),
        )
        .where(Order.id == order_id)
    )
    if user_id is not None:
        statement = statement.where(Order.user_id == user_id)
    order = await session.scalar(statement)
    if order is None:
        raise OrderError("ORDER_NOT_FOUND", "Order not found")
    return order


async def list_orders(session: AsyncSession, user_id: UUID, limit: int = 20, offset: int = 0) -> list[Order]:
    result = await session.scalars(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.flavors),
            selectinload(Order.items).selectinload(OrderItem.extras),
            selectinload(Order.payments),
            selectinload(Order.status_history),
        )
        .where(Order.user_id == user_id)
        .order_by(Order.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(result)


async def cancel_order(
    session: AsyncSession,
    order: Order,
    user_id: UUID,
    reason: str | None,
) -> Order:
    if order.user_id != user_id:
        raise OrderError("ORDER_NOT_FOUND", "Order not found")
    if "CANCELLED" not in ORDER_TRANSITIONS.get(order.status, set()):
        raise OrderError("ORDER_CANNOT_BE_CANCELLED", "Order can no longer be cancelled by the customer")
    await transition_order(session, order, "CANCELLED", None, reason or "Cancelled by customer")
    await session.commit()
    return await get_order(session, order.id, user_id)


async def transition_order(
    session: AsyncSession,
    order: Order,
    target_status: str,
    changed_by: UUID | None,
    reason: str | None,
) -> None:
    allowed_statuses = ORDER_TRANSITIONS.get(order.status, set())
    if target_status not in allowed_statuses:
        raise OrderError("INVALID_ORDER_TRANSITION", f"Cannot move order from {order.status} to {target_status}")
    if target_status == "OUT_FOR_DELIVERY" and order.fulfillment_type != "DELIVERY":
        raise OrderError("INVALID_ORDER_TRANSITION", "Pickup orders cannot go out for delivery")
    if target_status == "DELIVERED" and order.fulfillment_type == "DELIVERY" and order.status != "OUT_FOR_DELIVERY":
        raise OrderError("INVALID_ORDER_TRANSITION", "Delivery orders must leave for delivery first")
    previous_status = order.status
    order.status = target_status
    if target_status == "CONFIRMED":
        order.confirmed_at = datetime.now(UTC)
    if target_status == "DELIVERED":
        order.delivered_at = datetime.now(UTC)
    session.add(
        OrderStatusHistory(
            order_id=order.id,
            from_status=previous_status,
            to_status=target_status,
            changed_by=changed_by,
            reason=reason,
        )
    )
