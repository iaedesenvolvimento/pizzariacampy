import asyncio
from collections import defaultdict
from uuid import UUID

from fastapi import WebSocket


class RealtimeConnectionManager:
    def __init__(self) -> None:
        self._user_connections: dict[UUID, set[WebSocket]] = defaultdict(set)
        self._admin_connections: set[WebSocket] = set()
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, user_id: UUID, is_admin: bool) -> None:
        await websocket.accept()
        async with self._lock:
            self._user_connections[user_id].add(websocket)
            if is_admin:
                self._admin_connections.add(websocket)

    async def disconnect(self, websocket: WebSocket, user_id: UUID, is_admin: bool) -> None:
        async with self._lock:
            connections = self._user_connections.get(user_id)
            if connections is not None:
                connections.discard(websocket)
                if not connections:
                    self._user_connections.pop(user_id, None)
            if is_admin:
                self._admin_connections.discard(websocket)

    async def send_to_user(self, user_id: UUID, message: dict[str, object]) -> None:
        async with self._lock:
            connections = tuple(self._user_connections.get(user_id, ()))
        await self._send(connections, message)

    async def send_to_admins(self, message: dict[str, object]) -> None:
        async with self._lock:
            connections = tuple(self._admin_connections)
        await self._send(connections, message)

    async def _send(self, connections: tuple[WebSocket, ...], message: dict[str, object]) -> None:
        if not connections:
            return
        results = await asyncio.gather(
            *(connection.send_json(message) for connection in connections),
            return_exceptions=True,
        )
        for connection, result in zip(connections, results, strict=True):
            if isinstance(result, Exception):
                await self._remove_connection(connection)

    async def _remove_connection(self, websocket: WebSocket) -> None:
        async with self._lock:
            self._admin_connections.discard(websocket)
            for user_id, connections in tuple(self._user_connections.items()):
                connections.discard(websocket)
                if not connections:
                    self._user_connections.pop(user_id, None)


realtime_manager = RealtimeConnectionManager()


async def notify_order_created(order) -> None:
    payload = {
        "type": "order.created",
        "order_id": str(order.id),
        "order_number": order.order_number,
        "status": order.status,
        "total_amount": str(order.total_amount),
    }
    await realtime_manager.send_to_admins(payload)


async def notify_order_status_changed(order, previous_status: str) -> None:
    payload = {
        "type": "order.status_changed",
        "order_id": str(order.id),
        "order_number": order.order_number,
        "previous_status": previous_status,
        "status": order.status,
    }
    await realtime_manager.send_to_user(order.user_id, payload)
    await realtime_manager.send_to_admins(payload)
