from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.catalog import Edge, Extra, Flavor, FlavorSizePrice, Product, ProductSize
from app.services.coupons import CouponError, calculate_coupon_discount
from app.schemas.pricing import (
    PricingExtraBreakdown,
    PricingItemBreakdown,
    PricingItemInput,
    PricingQuoteRequest,
    PricingQuoteResponse,
)


ZERO = Decimal("0.00")


class PricingError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


async def calculate_quote(
    session: AsyncSession,
    request: PricingQuoteRequest,
    resolved_delivery_fee: Decimal = ZERO,
    user_id: UUID | None = None,
) -> PricingQuoteResponse:
    if resolved_delivery_fee < ZERO:
        raise PricingError("INVALID_DELIVERY_FEE", "Delivery fee cannot be negative")
    if request.fulfillment_type == "PICKUP" and resolved_delivery_fee != ZERO:
        raise PricingError("INVALID_DELIVERY_FEE", "Pickup cannot have a delivery fee")

    breakdowns: list[PricingItemBreakdown] = []
    subtotal = ZERO
    for item in request.items:
        breakdown = await calculate_item(session, item)
        breakdowns.append(breakdown)
        subtotal += breakdown.line_total

    try:
        discount_amount, _ = await calculate_coupon_discount(session, request.coupon_code, subtotal, user_id)
    except CouponError as error:
        raise PricingError(error.code, error.message) from error
    return PricingQuoteResponse(
        items=breakdowns,
        subtotal=subtotal,
        delivery_fee=resolved_delivery_fee,
        total_amount=max(ZERO, subtotal + resolved_delivery_fee - discount_amount),
        coupon_code=request.coupon_code,
        discount_amount=discount_amount,
    )


async def calculate_item(
    session: AsyncSession,
    item: PricingItemInput,
) -> PricingItemBreakdown:
    product = await session.get(Product, item.product_id)
    size = await session.get(ProductSize, item.product_size_id)
    if product is None or not product.is_active:
        raise PricingError("PRODUCT_UNAVAILABLE", "Product is unavailable")
    if size is None or not size.is_active or size.product_id != product.id:
        raise PricingError("SIZE_UNAVAILABLE", "Size is unavailable for this product")

    if item.quantity < 1:
        raise PricingError("INVALID_QUANTITY", "Quantity must be positive")
    if product.product_type == "PIZZA":
        if not item.flavor_ids:
            raise PricingError("FLAVOR_REQUIRED", "Pizza requires at least one flavor")
        if len(item.flavor_ids) != len(set(item.flavor_ids)):
            raise PricingError("DUPLICATE_FLAVOR", "A flavor cannot be repeated in the same item")
        if len(item.flavor_ids) > size.max_flavors:
            raise PricingError("FLAVOR_LIMIT_EXCEEDED", "Flavor limit exceeded for this size")
    elif item.flavor_ids:
        raise PricingError("FLAVOR_NOT_ALLOWED", "This product does not accept flavors")

    base_price = size.price
    if item.flavor_ids:
        flavor_prices = await get_flavor_prices(session, size.id, item.flavor_ids)
        base_price = max(flavor_prices.values())

    edge_price = ZERO
    if item.edge_id is not None:
        edge = await session.get(Edge, item.edge_id)
        if edge is None or not edge.is_active:
            raise PricingError("EDGE_UNAVAILABLE", "Edge is unavailable")
        edge_price = edge.price

    extras_total = ZERO
    extra_breakdowns: list[PricingExtraBreakdown] = []
    requested_extra_ids = [extra.extra_id for extra in item.extras]
    if len(requested_extra_ids) != len(set(requested_extra_ids)):
        raise PricingError("DUPLICATE_EXTRA", "An extra cannot be repeated in the same item")
    for requested_extra in item.extras:
        extra = await session.get(Extra, requested_extra.extra_id)
        if extra is None or not extra.is_active:
            raise PricingError("EXTRA_UNAVAILABLE", "Extra is unavailable")
        total_price = extra.price * requested_extra.quantity
        extras_total += total_price
        extra_breakdowns.append(
            PricingExtraBreakdown(
                extra_id=extra.id,
                quantity=requested_extra.quantity,
                unit_price=extra.price,
                total_price=total_price,
            )
        )

    unit_price = base_price + edge_price + extras_total
    line_total = unit_price * item.quantity
    return PricingItemBreakdown(
        product_id=product.id,
        product_size_id=size.id,
        flavor_ids=item.flavor_ids,
        base_price=base_price,
        edge_price=edge_price,
        extras_total=extras_total,
        unit_price=unit_price,
        quantity=item.quantity,
        line_total=line_total,
        extras=extra_breakdowns,
    )


async def get_flavor_prices(
    session: AsyncSession,
    product_size_id: UUID,
    flavor_ids: list[UUID],
) -> dict[UUID, Decimal]:
    result = await session.execute(
        select(FlavorSizePrice.flavor_id, FlavorSizePrice.price)
        .join(Flavor, Flavor.id == FlavorSizePrice.flavor_id)
        .where(
            FlavorSizePrice.product_size_id == product_size_id,
            FlavorSizePrice.flavor_id.in_(flavor_ids),
            Flavor.is_active.is_(True),
        )
    )
    prices = {flavor_id: price for flavor_id, price in result.all()}
    if len(prices) != len(set(flavor_ids)):
        raise PricingError("FLAVOR_UNAVAILABLE", "One or more flavors are unavailable")
    return prices
