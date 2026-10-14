from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.coupon import Coupon
from app.models.user import User
from app.schemas.coupons import CouponRequest, CouponResponse


router = APIRouter(prefix="/admin/coupons")


@router.get("", response_model=list[CouponResponse])
async def list_coupons(session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)) -> list[Coupon]:
    result = await session.scalars(select(Coupon).order_by(Coupon.created_at.desc()))
    return list(result)


@router.post("", response_model=CouponResponse, status_code=status.HTTP_201_CREATED)
async def create_coupon(payload: CouponRequest, session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)) -> Coupon:
    values = payload.model_dump()
    values["code"] = payload.code.strip().upper()
    coupon = Coupon(**values)
    session.add(coupon)
    await session.commit()
    await session.refresh(coupon)
    return coupon


@router.patch("/{coupon_id}", response_model=CouponResponse)
async def update_coupon(coupon_id: UUID, payload: CouponRequest, session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)) -> Coupon:
    coupon = await session.get(Coupon, coupon_id)
    if coupon is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Coupon not found")
    values = payload.model_dump()
    values["code"] = payload.code.strip().upper()
    for key, value in values.items():
        setattr(coupon, key, value)
    await session.commit()
    await session.refresh(coupon)
    return coupon
