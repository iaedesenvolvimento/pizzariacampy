from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.delivery import DeliveryZone
from app.models.user import User
from app.schemas.delivery import DeliveryZoneRequest, DeliveryZoneResponse
from app.services.delivery import list_active_zones


router = APIRouter(prefix="/delivery-zones")
admin_router = APIRouter(prefix="/admin/delivery-zones")


@router.get("", response_model=list[DeliveryZoneResponse])
async def get_delivery_zones(session: AsyncSession = Depends(get_session)) -> list[DeliveryZone]:
    return await list_active_zones(session)


@admin_router.get("", response_model=list[DeliveryZoneResponse])
async def list_admin_delivery_zones(
    session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)
) -> list[DeliveryZone]:
    result = await session.scalars(
        select(DeliveryZone).order_by(DeliveryZone.city, DeliveryZone.neighborhood)
    )
    return list(result)


@admin_router.post("", response_model=DeliveryZoneResponse, status_code=status.HTTP_201_CREATED)
async def create_delivery_zone(payload: DeliveryZoneRequest, session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)) -> DeliveryZone:
    zone = DeliveryZone(**payload.model_dump())
    session.add(zone)
    await session.commit()
    await session.refresh(zone)
    return zone


@admin_router.patch("/{zone_id}", response_model=DeliveryZoneResponse)
async def update_delivery_zone(zone_id: UUID, payload: DeliveryZoneRequest, session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)) -> DeliveryZone:
    zone = await session.get(DeliveryZone, zone_id)
    if zone is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery zone not found")
    for key, value in payload.model_dump().items():
        setattr(zone, key, value)
    await session.commit()
    await session.refresh(zone)
    return zone


@admin_router.delete("/{zone_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_delivery_zone(
    zone_id: UUID,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> None:
    zone = await session.get(DeliveryZone, zone_id)
    if zone is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Delivery zone not found")
    await session.delete(zone)
    await session.commit()
