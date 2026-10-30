"""Testes isolados do atendente; não fazem chamadas reais à OpenAI."""
from types import SimpleNamespace
from unittest.mock import AsyncMock

import httpx
import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.api.routes import ai


class FakeSession:
    def __init__(self, products):
        self.products = products

    async def scalars(self, _statement):
        return self.products


def test_chat_rejects_empty_message():
    with pytest.raises(ValidationError):
        ai.ChatRequest(message="")


def test_chat_rejects_long_message():
    with pytest.raises(ValidationError):
        ai.ChatRequest(message="x" * 501)


@pytest.mark.asyncio
async def test_chat_requires_server_key(monkeypatch):
    monkeypatch.setattr(ai.settings, "openai_api_key", None)
    monkeypatch.setattr(ai, "ai_rate_limiter", ai.InMemoryRateLimiter(10, 60))
    with pytest.raises(HTTPException) as error:
        await ai.chat(
            ai.ChatRequest(message="Quais pizzas existem?"),
            FakeSession([]),
            SimpleNamespace(id="test-user"),
        )
    assert error.value.status_code == 503


@pytest.mark.asyncio
async def test_chat_uses_active_catalog_without_prices(monkeypatch):
    monkeypatch.setattr(ai.settings, "openai_api_key", "test-key")
    monkeypatch.setattr(ai, "ai_rate_limiter", ai.InMemoryRateLimiter(10, 60))
    captured = {}

    class FakeResponse:
        def raise_for_status(self):
            pass

        def json(self):
            return {"output": [{"type": "message", "content": [
                {"type": "output_text", "text": "Temos pizza de mussarela!"}
            ]}]}

    class FakeClient:
        def __init__(self, **_kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_args):
            pass

        async def post(self, url, headers, json):
            captured.update(url=url, headers=headers, payload=json)
            return FakeResponse()

    monkeypatch.setattr(ai.httpx, "AsyncClient", FakeClient)
    products = [SimpleNamespace(name="Mussarela", product_type="PIZZA", description="Queijo")]
    result = await ai.chat(
        ai.ChatRequest(message="O que tem no cardápio?"),
        FakeSession(products),
        SimpleNamespace(id="customer-1"),
    )
    assert result.reply == "Temos pizza de mussarela!"
    assert "Mussarela" in captured["payload"]["instructions"]
    assert captured["payload"]["store"] is False
    assert captured["headers"]["Authorization"] == "Bearer test-key"


@pytest.mark.asyncio
async def test_chat_rate_limit(monkeypatch):
    monkeypatch.setattr(ai.settings, "openai_api_key", "test-key")
    monkeypatch.setattr(ai, "ai_rate_limiter", ai.InMemoryRateLimiter(0, 60))
    with pytest.raises(HTTPException) as error:
        await ai.chat(
            ai.ChatRequest(message="Oi"),
            FakeSession([]),
            SimpleNamespace(id="customer-2"),
        )
    assert error.value.status_code == 429
