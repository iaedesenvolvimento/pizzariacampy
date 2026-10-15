from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.coverage_location import CoverageLocation
from app.models.delivery import DeliveryZone
from app.models.user import User
from app.schemas.delivery import DeliveryZoneRequest, DeliveryZoneResponse
from app.schemas.coverage_locations import CoverageLocationResponse, CoverageLocationUpdate
from app.services.delivery import list_active_zones


router = APIRouter(prefix="/delivery-zones")
admin_router = APIRouter(prefix="/admin/delivery-zones")
locations_admin_router = APIRouter(prefix="/admin/coverage-locations")


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


@locations_admin_router.get("", response_model=list[CoverageLocationResponse])
async def list_coverage_locations(
    session: AsyncSession = Depends(get_session), _: User = Depends(get_admin_user)
) -> list[CoverageLocation]:
    result = await session.scalars(
        select(CoverageLocation).order_by(CoverageLocation.city, CoverageLocation.neighborhood)
    )
    return list(result)


@locations_admin_router.patch("/{location_id}", response_model=CoverageLocationResponse)
async def update_coverage_location(
    location_id: UUID,
    payload: CoverageLocationUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> CoverageLocation:
    location = await session.get(CoverageLocation, location_id)
    if location is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Coverage location not found")
    location.is_active = payload.is_active
    await session.commit()
    await session.refresh(location)
    return location
