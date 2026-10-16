import asyncio
import base64
import json
import logging
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.device_token import DeviceToken
from app.models.user import User

logger = logging.getLogger(__name__)
_firebase_app = None


def _get_app():
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    if not settings.firebase_service_account_base64:
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials

        raw = base64.b64decode(settings.firebase_service_account_base64).decode("utf-8")
        service_account = json.loads(raw)
        _firebase_app = firebase_admin.initialize_app(credentials.Certificate(service_account))
        return _firebase_app
    except Exception:
        logger.exception("Could not initialize Firebase Admin SDK")
        return None


async def send_push(tokens: list[str], title: str, body: str, data: dict[str, str]) -> None:
    if not tokens or _get_app() is None:
        return
    from firebase_admin import messaging

    def send() -> None:
        messaging.send_each(
            [
                messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data=data,
                    token=token,
                )
                for token in tokens
            ],
            app=_firebase_app,
        )

    try:
        await asyncio.to_thread(send)
    except Exception:
        logger.exception("Could not send Firebase notification")


async def tokens_for_user(session: AsyncSession, user_id: UUID) -> list[str]:
    result = await session.scalars(
        select(DeviceToken.token).where(
            DeviceToken.user_id == user_id,
            DeviceToken.is_active.is_(True),
        )
    )
    return list(result)


async def tokens_for_admins(session: AsyncSession) -> list[str]:
    result = await session.scalars(
        select(DeviceToken.token)
        .join(User, User.id == DeviceToken.user_id)
        .where(
            DeviceToken.is_active.is_(True),
            User.role.in_({"ADMIN", "MANAGER"}),
            User.is_active.is_(True),
        )
    )
    return list(result)


def order_data(order_id: UUID, order_number: str, status: str) -> dict[str, str]:
    return {
        "type": "order.status_changed",
        "order_id": str(order_id),
        "order_number": order_number,
        "status": status,
    }
