from uuid import UUID

import jwt
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.database import session_factory
from app.core.security import decode_access_token
from app.models.user import User
from app.services.realtime import realtime_manager

router = APIRouter()


@router.websocket("/ws/notifications")
async def notifications_websocket(websocket: WebSocket) -> None:
    authorization = websocket.headers.get("authorization", "")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = decode_access_token(token)
        user_id = UUID(str(payload["sub"]))
        async with session_factory() as session:
            user = await session.get(User, user_id)
            if user is None or not user.is_active:
                await websocket.close(code=1008)
                return
            is_admin = user.role in {"ADMIN", "MANAGER"}
            await realtime_manager.connect(websocket, user.id, is_admin)
        try:
            while True:
                await websocket.receive_text()
        except WebSocketDisconnect:
            pass
        finally:
            await realtime_manager.disconnect(websocket, user.id, is_admin)
    except (KeyError, TypeError, ValueError, jwt.InvalidTokenError):
        await websocket.close(code=1008)
