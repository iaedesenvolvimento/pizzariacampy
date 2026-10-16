from datetime import UTC, datetime

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_current_user
from app.models.device_token import DeviceToken
from app.models.user import User
from app.schemas.notifications import DeviceTokenRequest

router = APIRouter(prefix="/notifications")


@router.post("/devices", status_code=status.HTTP_204_NO_CONTENT)
async def register_device(
    payload: DeviceTokenRequest,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> None:
    device = await session.scalar(select(DeviceToken).where(DeviceToken.token == payload.token))
    if device is None:
        device = DeviceToken(
            user_id=current_user.id,
            token=payload.token,
            platform=payload.platform,
        )
        session.add(device)
    else:
        device.user_id = current_user.id
        device.platform = payload.platform
        device.is_active = True
        device.updated_at = datetime.now(UTC)
    await session.commit()


@router.delete("/devices/{token}", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_device(
    token: str,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> None:
    device = await session.scalar(
        select(DeviceToken).where(
            DeviceToken.token == token,
            DeviceToken.user_id == current_user.id,
        )
    )
    if device is not None:
        device.is_active = False
        await session.commit()
