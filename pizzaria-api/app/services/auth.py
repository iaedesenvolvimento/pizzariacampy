from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse


class AuthError(Exception):
    pass


async def register_user(
    session: AsyncSession,
    payload: RegisterRequest,
    user_agent: str | None,
) -> TokenResponse:
    normalized_email = str(payload.email).strip().lower()
    existing_user = await session.scalar(select(User).where(User.email == normalized_email))
    if existing_user is not None:
        raise AuthError("EMAIL_ALREADY_REGISTERED")

    user = User(
        name=payload.name.strip(),
        email=normalized_email,
        password_hash=hash_password(payload.password),
        role="CUSTOMER",
    )
    session.add(user)
    await session.flush()
    return await issue_tokens(session, user, user_agent)


async def authenticate_user(
    session: AsyncSession,
    payload: LoginRequest,
    user_agent: str | None,
) -> TokenResponse:
    normalized_email = str(payload.email).strip().lower()
    user = await session.scalar(select(User).where(User.email == normalized_email))
    if user is None or not user.is_active or not verify_password(payload.password, user.password_hash):
        raise AuthError("INVALID_CREDENTIALS")

    return await issue_tokens(session, user, user_agent)


async def issue_tokens(
    session: AsyncSession,
    user: User,
    user_agent: str | None,
) -> TokenResponse:
    refresh_token, token_hash, expires_at = create_refresh_token()
    session.add(
        RefreshToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=expires_at,
            user_agent=user_agent,
        )
    )
    await session.commit()
    return TokenResponse(
        access_token=create_access_token(user.id, user.role),
        refresh_token=refresh_token,
        user=user,
    )


async def rotate_refresh_token(
    session: AsyncSession,
    token: str,
    user_agent: str | None,
) -> TokenResponse:
    stored_token = await session.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_token(token))
    )
    now = datetime.now(UTC)
    if (
        stored_token is None
        or stored_token.revoked_at is not None
        or stored_token.expires_at <= now
    ):
        raise AuthError("INVALID_REFRESH_TOKEN")

    user = await session.get(User, stored_token.user_id)
    if user is None or not user.is_active:
        raise AuthError("INVALID_REFRESH_TOKEN")

    stored_token.revoked_at = now
    return await issue_tokens(session, user, user_agent)


async def revoke_refresh_token(session: AsyncSession, token: str) -> None:
    stored_token = await session.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_token(token))
    )
    if stored_token is not None and stored_token.revoked_at is None:
        stored_token.revoked_at = datetime.now(UTC)
        await session.commit()
