from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.business_hours import BusinessHours


SAO_PAULO = ZoneInfo("America/Sao_Paulo")


async def get_hours(session: AsyncSession) -> list[BusinessHours]:
    result = await session.scalars(select(BusinessHours).order_by(BusinessHours.weekday))
    return list(result)


async def get_business_status(session: AsyncSession) -> dict[str, str | None]:
    now = datetime.now(UTC).astimezone(SAO_PAULO)
    rows = {row.weekday: row for row in await get_hours(session)}
    today = rows.get(now.weekday())
    current_time = now.time().replace(tzinfo=None)
    is_open = bool(today and not today.is_closed and today.open_time and today.close_time and today.open_time <= current_time < today.close_time)
    if is_open:
        return {"status": "OPEN", "message": "Aberto", "next_open_at": None, "server_time": now.isoformat()}
    for offset in range(0, 8):
        candidate_day = now + timedelta(days=offset)
        row = rows.get(candidate_day.weekday())
        if not row or row.is_closed or not row.open_time:
            continue
        if offset == 0 and row.open_time <= current_time:
            continue
        next_open = candidate_day.replace(hour=row.open_time.hour, minute=row.open_time.minute, second=0, microsecond=0)
        return {"status": "CLOSED", "message": f"Fechado — abre às {next_open.strftime('%d/%m %H:%M')}", "next_open_at": next_open.isoformat(), "server_time": now.isoformat()}
    return {"status": "CLOSED", "message": "Fechado", "next_open_at": None, "server_time": now.isoformat()}
