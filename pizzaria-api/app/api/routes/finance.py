from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.user import User
from app.schemas.finance import (
    FinanceCancellationsResponse,
    FinancePaymentMethodsResponse,
    FinancePixPendingResponse,
    FinanceSalesResponse,
    FinanceSummaryResponse,
)
from app.services.finance import (
    get_cancellations,
    get_payment_methods,
    get_pix_pending,
    get_sales,
    get_summary,
)

router = APIRouter(prefix="/admin/finance")


def _period_error(error: ValueError) -> HTTPException:
    return HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(error))


@router.get("/summary", response_model=FinanceSummaryResponse)
async def finance_summary(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FinanceSummaryResponse:
    try:
        return await get_summary(session, start_date, end_date)
    except ValueError as error:
        raise _period_error(error) from error


@router.get("/sales", response_model=FinanceSalesResponse)
async def finance_sales(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    payment_method: str | None = Query(default=None),
    payment_status: str | None = Query(default=None),
    order_status: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FinanceSalesResponse:
    try:
        return await get_sales(
            session, start_date, end_date, limit, offset,
            payment_method, payment_status, order_status,
        )
    except ValueError as error:
        raise _period_error(error) from error


@router.get("/payment-methods", response_model=FinancePaymentMethodsResponse)
async def finance_payment_methods(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FinancePaymentMethodsResponse:
    try:
        return await get_payment_methods(session, start_date, end_date)
    except ValueError as error:
        raise _period_error(error) from error


@router.get("/pix-pending", response_model=FinancePixPendingResponse)
async def finance_pix_pending(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FinancePixPendingResponse:
    try:
        return await get_pix_pending(session, start_date, end_date, limit, offset)
    except ValueError as error:
        raise _period_error(error) from error


@router.get("/cancellations", response_model=FinanceCancellationsResponse)
async def finance_cancellations(
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FinanceCancellationsResponse:
    try:
        return await get_cancellations(session, start_date, end_date, limit, offset)
    except ValueError as error:
        raise _period_error(error) from error
