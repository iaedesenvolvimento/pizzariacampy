import unicodedata

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.delivery import DeliveryZone


NEIGHBORHOOD_ALIASES = {
    "cidade ariston estela azevedo": "ariston",
    "parque roseira": "roseira parque",
}


def _normalize_location(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.strip().lower())
    return "".join(char for char in decomposed if not unicodedata.combining(char))


def _canonical_neighborhood(value: str) -> str:
    normalized = _normalize_location(value)
    return NEIGHBORHOOD_ALIASES.get(normalized, normalized)


async def list_active_zones(session: AsyncSession) -> list[DeliveryZone]:
    result = await session.scalars(select(DeliveryZone).where(DeliveryZone.is_active.is_(True)).order_by(DeliveryZone.neighborhood))
    return list(result)


async def resolve_zone(session: AsyncSession, neighborhood: str | None, city: str | None) -> DeliveryZone | None:
    if not neighborhood or not city:
        return None
    zones = await session.scalars(
        select(DeliveryZone).where(DeliveryZone.is_active.is_(True))
    )
    target_neighborhood = _canonical_neighborhood(neighborhood)
    target_city = _normalize_location(city)
    return next(
        (
            zone
            for zone in zones
            if _canonical_neighborhood(zone.neighborhood) == target_neighborhood
            and _normalize_location(zone.city) == target_city
        ),
        None,
    )


async def resolve_zone_by_postal_code(
    session: AsyncSession,
    postal_code: str | None,
) -> tuple[DeliveryZone | None, str | None, str | None]:
    digits = ''.join(character for character in (postal_code or '') if character.isdigit())
    if len(digits) != 8:
        return None, None, None
    async with httpx.AsyncClient(timeout=5.0) as client:
        response = await client.get(f'https://viacep.com.br/ws/{digits}/json/')
        response.raise_for_status()
        payload = response.json()
    if not isinstance(payload, dict) or payload.get('erro') is True:
        return None, None, None
    neighborhood = str(payload.get('bairro') or '').strip()
    city = str(payload.get('localidade') or '').strip()
    if not neighborhood or not city:
        return None, neighborhood or None, city or None
    zone = await resolve_zone(session, neighborhood, city)
    return zone, neighborhood, city
