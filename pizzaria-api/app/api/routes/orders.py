from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_session
from app.dependencies.auth import get_admin_user, get_current_user
from app.models.order import Order
from app.models.user import User
from app.schemas.admin import AdminOrderSummary
from app.schemas.orders import (
    CancelOrderRequest,
    CreateOrderRequest,
    OrderResponse,
    UpdateOrderStatusRequest,
)
from app.services.firebase import (
    order_data,
    send_push,
    tokens_for_admins,
    tokens_for_user,
)
from app.services.orders import (
    OrderError,
    cancel_order,
    create_order,
    get_order,
    list_orders,
    transition_order,
)
from app.services.realtime import (
    notify_order_created,
    notify_order_status_changed,
)

router = APIRouter(prefix="/orders")
admin_router = APIRouter(prefix="/admin/orders")


def admin_order_summary(order: Order, customer: User) -> AdminOrderSummary:
    payment = order.payments[-1] if order.payments else None
    return AdminOrderSummary(
        id=str(order.id),
        order_number=order.order_number,
        status=order.status,
        fulfillment_type=order.fulfillment_type,
        total_amount=order.total_amount,
        created_at=order.created_at,
        payment_id=str(payment.id) if payment else None,
        payment_status=payment.status if payment else None,
        proof_url=payment.proof_url if payment else None,
        customer_name=customer.name,
        customer_phone=customer.phone,
        customer_email=customer.email,
        delivery_address_snapshot=order.delivery_address_snapshot,
    )


def order_error_response(error: OrderError) -> HTTPException:
    error_status = status.HTTP_404_NOT_FOUND if error.code == "ORDER_NOT_FOUND" else status.HTTP_422_UNPROCESSABLE_ENTITY
    return HTTPException(
        status_code=error_status,
        detail={"code": error.code, "message": error.message},
    )


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_customer_order(
    payload: CreateOrderRequest,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> Order:
    try:
        order = await create_order(session, current_user.id, payload)
        await notify_order_created(order)
        await send_push(
            await tokens_for_admins(session),
            "Novo pedido recebido",
            f"Pedido {order.order_number} aguardando confirmação.",
            order_data(order.id, order.order_number, order.status),
        )
        return order
    except OrderError as error:
        await session.rollback()
        raise order_error_response(error) from error


@router.get("", response_model=list[OrderResponse])
async def get_customer_orders(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> list[Order]:
    return await list_orders(session, current_user.id, limit, offset)


@router.get("/{order_id}", response_model=OrderResponse)
async def get_customer_order(
    order_id: UUID,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> Order:
    try:
        return await get_order(session, order_id, current_user.id)
    except OrderError as error:
        raise order_error_response(error) from error


@router.post("/{order_id}/cancel", response_model=OrderResponse)
async def cancel_customer_order(
    order_id: UUID,
    payload: CancelOrderRequest,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> Order:
    try:
        order = await get_order(session, order_id, current_user.id)
        return await cancel_order(session, order, current_user.id, payload.reason)
    except OrderError as error:
        await session.rollback()
        raise order_error_response(error) from error


@admin_router.patch("/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: UUID,
    payload: UpdateOrderStatusRequest,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_admin_user),
) -> Order:
    try:
        order = await get_order(session, order_id)
        previous_status = order.status
        await transition_order(session, order, payload.status, current_user.id, payload.reason)
        await session.commit()
        updated_order = await get_order(session, order.id)
        await notify_order_status_changed(updated_order, previous_status)
        data = order_data(updated_order.id, updated_order.order_number, updated_order.status)
        await send_push(
            await tokens_for_user(session, updated_order.user_id),
            "Atualização do pedido",
            f"Pedido {updated_order.order_number}: {updated_order.status}.",
            data,
        )
        await send_push(
            await tokens_for_admins(session),
            "Pedido atualizado",
            f"Pedido {updated_order.order_number}: {updated_order.status}.",
            data,
        )
        return updated_order
    except OrderError as error:
        await session.rollback()
        raise order_error_response(error) from error


@admin_router.get("", response_model=list[AdminOrderSummary])
async def list_admin_orders(
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[AdminOrderSummary]:
    statement = (
        select(Order, User)
        .join(User, User.id == Order.user_id)
        .options(selectinload(Order.payments))
        .order_by(Order.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    if status_filter:
        statement = statement.where(Order.status == status_filter)
    orders = list((await session.execute(statement)).all())
    return [admin_order_summary(order, customer) for order, customer in orders]
