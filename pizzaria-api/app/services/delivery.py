from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.delivery import DeliveryZone


async def list_active_zones(session: AsyncSession) -> list[DeliveryZone]:
    result = await session.scalars(select(DeliveryZone).where(DeliveryZone.is_active.is_(True)).order_by(DeliveryZone.neighborhood))
    return list(result)


async def resolve_zone(session: AsyncSession, neighborhood: str | None, city: str | None) -> DeliveryZone | None:
    if not neighborhood or not city:
        return None
    return await session.scalar(
        select(DeliveryZone).where(
            DeliveryZone.is_active.is_(True),
            func.lower(DeliveryZone.neighborhood) == neighborhood.strip().lower(),
            func.lower(DeliveryZone.city) == city.strip().lower(),
        )
    )
