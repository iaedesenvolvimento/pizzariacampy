from datetime import UTC, date, datetime, time, timedelta
from decimal import ROUND_HALF_UP, Decimal
from zoneinfo import ZoneInfo

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.order import Order, Payment
from app.schemas.finance import (
    FinanceCancellationItem,
    FinanceCancellationsResponse,
    FinancePaymentMethodsResponse,
    FinancePaymentMethodSummary,
    FinancePixPendingItem,
    FinancePixPendingResponse,
    FinanceSaleItem,
    FinanceSalesResponse,
    FinanceSummaryResponse,
)

ZERO = Decimal("0.00")
SALES_DEFINITION = "Pedidos não cancelados cujo pagamento não esteja FAILED; isso representa faturamento operacional, não recebimento confirmado."


def _timezone() -> ZoneInfo:
    return ZoneInfo(settings.timezone)


def resolve_period(start_date: date | None, end_date: date | None) -> tuple[date, date, datetime, datetime]:
    if (start_date is None) != (end_date is None):
        raise ValueError("start_date e end_date devem ser informados juntos")
    if start_date is None:
        local_today = datetime.now(UTC).astimezone(_timezone()).date()
        start_date = local_today
        end_date = local_today
    if end_date < start_date:
        raise ValueError("end_date deve ser maior ou igual a start_date")
    local_zone = _timezone()
    start_local = datetime.combine(start_date, time.min, tzinfo=local_zone)
    end_local = datetime.combine(end_date + timedelta(days=1), time.min, tzinfo=local_zone)
    return start_date, end_date, start_local.astimezone(UTC), end_local.astimezone(UTC)


def _period_filter(start_utc: datetime, end_utc: datetime):
    return and_(Order.created_at >= start_utc, Order.created_at < end_utc)


def _sale_filter():
    return and_(Order.status != "CANCELLED", Order.payment_status != "FAILED")


def _method_summaries(rows) -> list[FinancePaymentMethodSummary]:
    return [
        FinancePaymentMethodSummary(
            method=method,
            order_count=count,
            amount=Decimal(amount or ZERO).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
        )
        for method, count, amount in rows
    ]


async def _decimal(session: AsyncSession, statement) -> Decimal:
    value = await session.scalar(statement)
    return Decimal(value or ZERO).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


async def get_summary(
    session: AsyncSession,
    start_date: date | None,
    end_date: date | None,
) -> FinanceSummaryResponse:
    start_date, end_date, start_utc, end_utc = resolve_period(start_date, end_date)
    period = _period_filter(start_utc, end_utc)
    sales = and_(period, _sale_filter())
    orders_count = int(await session.scalar(select(func.count()).select_from(Order).where(sales)) or 0)
    gross_sales = await _decimal(session, select(func.sum(Order.total_amount)).where(sales))
    discounts_total = await _decimal(session, select(func.sum(Order.discount_amount)).where(sales))
    delivery_fees_total = await _decimal(session, select(func.sum(Order.delivery_fee)).where(sales))
    average_ticket = (gross_sales / orders_count if orders_count else ZERO).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    cancelled = and_(period, Order.status == "CANCELLED")
    cancelled_orders_count = int(
        await session.scalar(select(func.count()).select_from(Order).where(cancelled)) or 0
    )
    cancelled_amount = await _decimal(session, select(func.sum(Order.total_amount)).where(cancelled))
    pix_pending = and_(period, Order.payment_method == "PIX", Order.payment_status == "PENDING")
    pix_review = and_(period, Order.payment_method == "PIX", Order.payment_status == "UNDER_REVIEW")
    pix_pending_count = int(await session.scalar(select(func.count()).select_from(Order).where(and_(pix_pending, Order.status != "CANCELLED"))) or 0)
    pix_awaiting_review_count = int(await session.scalar(select(func.count()).select_from(Order).where(and_(pix_review, Order.status != "CANCELLED"))) or 0)
    methods_result = await session.execute(
        select(Order.payment_method, func.count(), func.sum(Order.total_amount))
        .where(sales)
        .group_by(Order.payment_method)
        .order_by(Order.payment_method)
    )
    payment_methods = _method_summaries(methods_result.all())
    return FinanceSummaryResponse(
        start_date=start_date,
        end_date=end_date,
        timezone=settings.timezone,
        sales_definition=SALES_DEFINITION,
        gross_sales=gross_sales,
        orders_count=orders_count,
        average_ticket=average_ticket,
        discounts_total=discounts_total,
        delivery_fees_total=delivery_fees_total,
        cancelled_orders_count=cancelled_orders_count,
        cancelled_amount=cancelled_amount,
        pix_pending_count=pix_pending_count + pix_awaiting_review_count,
        pix_awaiting_proof_count=pix_pending_count,
        pix_awaiting_review_count=pix_awaiting_review_count,
        payment_methods=payment_methods,
    )


async def get_payment_methods(
    session: AsyncSession,
    start_date: date | None,
    end_date: date | None,
) -> FinancePaymentMethodsResponse:
    start_date, end_date, start_utc, end_utc = resolve_period(start_date, end_date)
    result = await session.execute(
        select(Order.payment_method, func.count(), func.sum(Order.total_amount))
        .where(_period_filter(start_utc, end_utc), _sale_filter())
        .group_by(Order.payment_method)
        .order_by(Order.payment_method)
    )
    return FinancePaymentMethodsResponse(
        items=_method_summaries(result.all()),
        start_date=start_date,
        end_date=end_date,
        timezone=settings.timezone,
    )


async def get_sales(
    session: AsyncSession,
    start_date: date | None,
    end_date: date | None,
    limit: int,
    offset: int,
    payment_method: str | None,
    payment_status: str | None,
    order_status: str | None,
) -> FinanceSalesResponse:
    start_date, end_date, start_utc, end_utc = resolve_period(start_date, end_date)
    filters = [_period_filter(start_utc, end_utc), _sale_filter()]
    if payment_method:
        filters.append(Order.payment_method == payment_method)
    if payment_status:
        filters.append(Order.payment_status == payment_status)
    if order_status:
        filters.append(Order.status == order_status)
    statement = select(Order).where(*filters).order_by(Order.created_at.desc()).limit(limit).offset(offset)
    orders = list(await session.scalars(statement))
    total = int(await session.scalar(select(func.count()).select_from(Order).where(*filters)) or 0)
    return FinanceSalesResponse(
        items=[
            FinanceSaleItem(
                order_id=str(order.id), order_number=order.order_number, created_at=order.created_at,
                subtotal=order.subtotal, discount_amount=order.discount_amount,
                delivery_fee=order.delivery_fee, total_amount=order.total_amount,
                payment_method=order.payment_method, payment_status=order.payment_status,
                order_status=order.status,
            )
            for order in orders
        ],
        total=total, limit=limit, offset=offset, start_date=start_date, end_date=end_date,
        timezone=settings.timezone,
    )


async def get_pix_pending(
    session: AsyncSession,
    start_date: date | None,
    end_date: date | None,
    limit: int,
    offset: int,
) -> FinancePixPendingResponse:
    start_date, end_date, start_utc, end_utc = resolve_period(start_date, end_date)
    filters = [
        _period_filter(start_utc, end_utc),
        Order.payment_method == "PIX",
        Order.payment_status.in_(["PENDING", "UNDER_REVIEW"]),
        Order.status != "CANCELLED",
    ]
    proof_url = (
        select(Payment.proof_url)
        .where(Payment.order_id == Order.id)
        .order_by(Payment.created_at.desc())
        .limit(1)
        .scalar_subquery()
    )
    statement = (
        select(Order, proof_url)
        .where(*filters)
        .order_by(Order.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    rows = list((await session.execute(statement)).all())
    total = int(await session.scalar(select(func.count()).select_from(Order).where(*filters)) or 0)
    return FinancePixPendingResponse(
        items=[
            FinancePixPendingItem(
                order_id=str(order.id), order_number=order.order_number, created_at=order.created_at,
                total_amount=order.total_amount, payment_status=order.payment_status,
                order_status=order.status, proof_url=proof_url if order.payment_status == "UNDER_REVIEW" else None,
            )
            for order, proof_url in rows
        ],
        total=total, limit=limit, offset=offset, start_date=start_date, end_date=end_date,
        timezone=settings.timezone,
    )


async def get_cancellations(
    session: AsyncSession,
    start_date: date | None,
    end_date: date | None,
    limit: int,
    offset: int,
) -> FinanceCancellationsResponse:
    start_date, end_date, start_utc, end_utc = resolve_period(start_date, end_date)
    filters = [_period_filter(start_utc, end_utc), Order.status == "CANCELLED"]
    statement = select(Order).where(*filters).order_by(Order.created_at.desc()).limit(limit).offset(offset)
    orders = list(await session.scalars(statement))
    total = int(await session.scalar(select(func.count()).select_from(Order).where(*filters)) or 0)
    return FinanceCancellationsResponse(
        items=[
            FinanceCancellationItem(
                order_id=str(order.id), order_number=order.order_number, created_at=order.created_at,
                total_amount=order.total_amount, payment_method=order.payment_method,
                payment_status=order.payment_status, order_status=order.status,
                cancelled_reason=order.cancelled_reason,
                payment_confirmed=order.payment_status == "CONFIRMED",
            )
            for order in orders
        ],
        total=total, limit=limit, offset=offset, start_date=start_date, end_date=end_date,
        timezone=settings.timezone,
    )
