from functools import lru_cache
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


def normalize_async_database_url(database_url: str) -> str:
    parsed = urlsplit(database_url)
    scheme = parsed.scheme
    if scheme in {"postgres", "postgresql"}:
        scheme = "postgresql+asyncpg"

    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    sslmode = query.pop("sslmode", None)
    query.pop("channel_binding", None)
    if sslmode and "ssl" not in query:
        query["ssl"] = sslmode

    return urlunsplit((scheme, parsed.netloc, parsed.path, urlencode(query), parsed.fragment))


class Settings(BaseSettings):
    openai_api_key: str | None = None
    openai_model: str = "gpt-4.1-mini"
    app_name: str = "Pizzaria Campy API"
    app_env: str = "development"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"
    database_url: str
    database_pool_size: int = Field(default=5, ge=1)
    database_max_overflow: int = Field(default=10, ge=0)
    database_pool_timeout: int = Field(default=30, ge=1)
    database_pool_recycle: int = Field(default=1800, ge=0)
    allowed_origins: str = ""
    timezone: str = "America/Sao_Paulo"
    secret_key: str = Field(min_length=32)
    access_token_expire_minutes: int = Field(default=15, ge=1)
    refresh_token_expire_days: int = Field(default=30, ge=1)
    password_reset_expire_minutes: int = Field(default=30, ge=5)
    smtp_host: str | None = None
    smtp_port: int = Field(default=587, ge=1, le=65535)
    smtp_username: str | None = None
    smtp_password: str | None = None
    smtp_from_email: str | None = None
    smtp_use_tls: bool = True
    brevo_api_key: str | None = None
    brevo_from_email: str | None = None
    brevo_from_name: str = "Pizzaria Campy"
    public_app_url: str = "http://localhost:8000"
    cloudinary_cloud_name: str | None = None
    cloudinary_api_key: str | None = None
    cloudinary_api_secret: str | None = None
    cloudinary_upload_folder: str = "pizzaria-campy/products"
    firebase_service_account_base64: str | None = None
    mercado_pago_access_token: str | None = None
    mercado_pago_public_key: str | None = None
    mercado_pago_webhook_secret: str | None = None
    mercado_pago_environment: str = "test"
    mercado_pago_webhook_url: str | None = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def allowed_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]

    @property
    def async_database_url(self) -> str:
        return normalize_async_database_url(self.database_url)


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
