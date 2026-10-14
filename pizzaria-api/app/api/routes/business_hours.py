from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.business_hours import BusinessHours
from app.models.user import User
from app.schemas.business_hours import BusinessHoursRequest, BusinessHoursResponse, BusinessStatusResponse
from app.services.business_hours import get_business_status, get_hours


router = APIRouter()
admin_router = APIRouter(prefix="/admin/hours")


@router.get("/business-status", response_model=BusinessStatusResponse)
async def business_status(session: AsyncSession = Depends(get_session)) -> dict[str, str | None]:
    return await get_business_status(session)


@admin_router.get("", response_model=list[BusinessHoursResponse])
async def list_business_hours(session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)) -> list[BusinessHours]:
    return await get_hours(session)


@admin_router.put("/{weekday}", response_model=BusinessHoursResponse)
async def save_business_hours(
    weekday: int,
    payload: BusinessHoursRequest,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> BusinessHours:
    if weekday < 0 or weekday > 6:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid weekday")
    if not payload.is_closed and (payload.open_time is None or payload.close_time is None):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Open and close times are required")
    if payload.open_time and payload.close_time and payload.open_time >= payload.close_time:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Close time must be after open time")
    row = await session.scalar(select(BusinessHours).where(BusinessHours.weekday == weekday))
    if row is None:
        row = BusinessHours(weekday=weekday)
        session.add(row)
    row.open_time = payload.open_time
    row.close_time = payload.close_time
    row.is_closed = payload.is_closed
    await session.commit()
    await session.refresh(row)
    return row
