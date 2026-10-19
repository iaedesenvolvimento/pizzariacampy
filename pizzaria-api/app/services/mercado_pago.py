import hashlib
import hmac
from decimal import Decimal
from uuid import UUID

import httpx

from app.core.config import settings


class MercadoPagoError(Exception):
    pass


def _headers(idempotency_key: str | None = None) -> dict[str, str]:
    if not settings.mercado_pago_access_token:
        raise MercadoPagoError("Mercado Pago não está configurado.")
    headers = {
        "Authorization": f"Bearer {settings.mercado_pago_access_token}",
        "Content-Type": "application/json",
    }
    if idempotency_key:
        headers["X-Idempotency-Key"] = idempotency_key
    return headers


async def create_pix_payment(
    *,
    order_id: UUID,
    order_number: str,
    amount: Decimal,
    payer_email: str,
) -> dict:
    body = {
        "type": "online",
        "total_amount": f"{amount:.2f}",
        "external_reference": str(order_id),
        "processing_mode": "automatic",
        "description": f"Pedido {order_number} - Pizzaria Campy",
        "transactions": {
            "payments": [
                {
                    "amount": f"{amount:.2f}",
                    "payment_method": {"id": "pix", "type": "bank_transfer"},
                }
            ]
        },
        "payer": {"email": payer_email},
    }
    if settings.mercado_pago_webhook_url:
        body["notification_url"] = settings.mercado_pago_webhook_url
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            "https://api.mercadopago.com/v1/orders",
            headers=_headers(f"campy-{order_id}"),
            json=body,
        )
    if response.status_code >= 400:
        raise MercadoPagoError("Mercado Pago recusou a criação do pagamento.")
    return response.json()


async def get_order(order_id: str) -> dict:
    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.get(
            f"https://api.mercadopago.com/v1/orders/{order_id}",
            headers=_headers(),
        )
    if response.status_code >= 400:
        raise MercadoPagoError("Não foi possível consultar o pagamento.")
    return response.json()


async def get_payment(payment_id: str) -> dict:
    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.get(
            f"https://api.mercadopago.com/v1/payments/{payment_id}",
            headers=_headers(),
        )
    if response.status_code >= 400:
        raise MercadoPagoError("Não foi possível consultar o pagamento.")
    return response.json()


def payment_status(value: str) -> str:
    return {
        "approved": "CONFIRMED",
        "processed": "CONFIRMED",
        "rejected": "FAILED",
        "cancelled": "FAILED",
        "expired": "FAILED",
    }.get(value, "PENDING")


def valid_webhook_signature(*, signature: str | None, request_id: str | None, payment_id: str) -> bool:
    secret = settings.mercado_pago_webhook_secret
    if not secret:
        return settings.mercado_pago_environment != "production"
    if not signature or not request_id:
        return False
    values = dict(
        part.split("=", 1)
        for part in signature.split(",")
        if "=" in part
    )
    ts = values.get("ts")
    v1 = values.get("v1")
    if not ts or not v1:
        return False
    manifest = f"id:{payment_id};request-id:{request_id};ts:{ts};"
    digest = hmac.new(secret.encode(), manifest.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(digest, v1)
