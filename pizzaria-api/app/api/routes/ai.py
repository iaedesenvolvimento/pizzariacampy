"""MVP do atendente: consulta somente produtos ativos; não altera pedidos."""
import logging

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_session
from app.core.rate_limit import InMemoryRateLimiter
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.catalog import Product

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/ai", tags=["ai-attendant"])
ai_rate_limiter = InMemoryRateLimiter(limit=10, window_seconds=60)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=500)


class ChatResponse(BaseModel):
    reply: str


@router.post("/chat", response_model=ChatResponse)
async def chat(\n    request: ChatRequest,\n    session: AsyncSession = Depends(get_session),\n    user: User = Depends(get_current_user),\n) -> ChatResponse:
    """Responde dúvidas do cardápio; preços e pedidos ficam fora deste MVP."""
    allowed, retry_after = ai_rate_limiter.allow(str(user.id))
    if not allowed:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Muitas mensagens. Aguarde um minuto.", headers={"Retry-After": str(retry_after)})
    if not settings.openai_api_key:
        raise HTTPException(status_code=503, detail="Atendente indisponível")

    products = list(await session.scalars(
        select(Product).where(Product.is_active.is_(True))
        .order_by(Product.sort_order, Product.name).limit(100)
    ))
    menu = "\n".join(
        f"- {p.name} ({p.product_type}): {(p.description or 'Sem descrição')[:180]}"
        for p in products
    ) or "Nenhum produto disponível."

    payload = {
        "model": settings.openai_model,
        "instructions": (
            "Você é o atendente da Pizzaria Campy. Responda em português brasileiro, "
            "com clareza e simpatia. Use exclusivamente o cardápio fornecido. "
            "Não invente produtos, preços, disponibilidade de tamanhos, frete ou prazos. "
            "Não solicite dados pessoais. Não diga que adicionou itens ao carrinho "
            "ou concluiu pedidos: essa funcionalidade ainda não existe. "
            "Quando perguntarem preços ou quiserem fechar pedido, oriente a usar "
            "o cardápio e o carrinho do aplicativo.\n\nCardápio:\n" + menu
        ),
        "input": request.message,
        "max_output_tokens": 250,
        "store": False,
    }
    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            response = await client.post(
                "https://api.openai.com/v1/responses",
                headers={"Authorization": f"Bearer {settings.openai_api_key}"},
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError):
        logger.warning("Falha no provedor de IA", exc_info=True)
        raise HTTPException(status_code=503, detail="Atendente temporariamente indisponível")

    reply = "Desculpe, não consegui responder agora. Consulte o cardápio no aplicativo."
    for item in data.get("output", []):
        if item.get("type") == "message":
            texts = [part.get("text", "") for part in item.get("content", [])
                     if part.get("type") == "output_text"]
            if texts:
                reply = "\n".join(texts)
                break
    return ChatResponse(reply=reply)
