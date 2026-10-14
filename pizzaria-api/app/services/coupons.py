from datetime import UTC, datetime
from decimal import Decimal, ROUND_HALF_UP
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.coupon import Coupon, CouponRedemption


class CouponError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code
        self.message = message


def compute_discount(discount_type: str, value: Decimal, subtotal: Decimal) -> Decimal:
    value = Decimal(value)
    subtotal = Decimal(subtotal)
    if discount_type == "PERCENTAGE" and value > 100:
        raise CouponError("COUPON_INVALID_VALUE", "Percentage cannot exceed 100")
    discount = value if discount_type == "FIXED" else subtotal * value / Decimal("100")
    return min(discount, subtotal).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


async def calculate_coupon_discount(session: AsyncSession, code: str | None, subtotal: Decimal, user_id: UUID | None = None) -> tuple[Decimal, Coupon | None]:
    if not code:
        return Decimal("0.00"), None
    coupon = await session.scalar(select(Coupon).where(func.upper(Coupon.code) == code.strip().upper(), Coupon.is_active.is_(True)))
    if coupon is None:
        raise CouponError("COUPON_INVALID", "Coupon is invalid or inactive")
    now = datetime.now(UTC)
    if coupon.starts_at and now < coupon.starts_at:
        raise CouponError("COUPON_NOT_STARTED", "Coupon is not valid yet")
    if coupon.ends_at and now > coupon.ends_at:
        raise CouponError("COUPON_EXPIRED", "Coupon has expired")
    if coupon.usage_limit is not None and coupon.usage_count >= coupon.usage_limit:
        raise CouponError("COUPON_USAGE_LIMIT", "Coupon usage limit reached")
    if subtotal < coupon.minimum_order_amount:
        raise CouponError("COUPON_MINIMUM_NOT_REACHED", f"Minimum order for coupon is {coupon.minimum_order_amount}")
    if user_id is not None and coupon.per_customer_limit is not None:
        customer_uses = await session.scalar(select(func.count()).select_from(CouponRedemption).where(CouponRedemption.coupon_id == coupon.id, CouponRedemption.user_id == user_id)) or 0
        if customer_uses >= coupon.per_customer_limit:
            raise CouponError("COUPON_CUSTOMER_LIMIT", "Coupon customer limit reached")
    return compute_discount(coupon.discount_type, coupon.value, subtotal), coupon
