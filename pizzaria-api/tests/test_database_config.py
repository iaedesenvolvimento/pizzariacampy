import os

os.environ["DATABASE_URL"] = "postgresql+asyncpg://test:test@localhost/test"
os.environ["SECRET_KEY"] = "test-secret-key-with-at-least-32-bytes-long"
os.environ["DEBUG"] = "false"

from app.core.config import normalize_async_database_url


def test_normalizes_neon_connection_string_for_asyncpg() -> None:
    url = "postgresql://user:password@ep-example.neon.tech/db?sslmode=require&channel_binding=require"

    assert normalize_async_database_url(url) == (
        "postgresql+asyncpg://user:password@ep-example.neon.tech/db?"
        "ssl=require"
    )


def test_preserves_asyncpg_connection_string() -> None:
    url = "postgresql+asyncpg://user:password@localhost/db"

    assert normalize_async_database_url(url) == url
