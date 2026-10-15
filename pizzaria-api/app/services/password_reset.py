import asyncio
import logging
import secrets
import smtplib
from datetime import UTC, datetime, timedelta
from email.message import EmailMessage

import httpx

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import hash_password, hash_token
from app.models.password_reset import PasswordResetToken
from app.models.user import User
from app.schemas.auth import PasswordResetRequest


logger = logging.getLogger(__name__)


async def request_password_reset(session: AsyncSession, email: str) -> None:
    user = await session.scalar(select(User).where(User.email == email.strip().lower()))
    if user is None or not user.is_active:
        return

    await session.execute(delete(PasswordResetToken).where(PasswordResetToken.user_id == user.id))
    raw_token = secrets.token_urlsafe(32)
    token = PasswordResetToken(
        user_id=user.id,
        token_hash=hash_token(raw_token),
        expires_at=datetime.now(UTC) + timedelta(minutes=settings.password_reset_expire_minutes),
    )
    session.add(token)
    await session.commit()
    reset_url = f"{settings.public_app_url.rstrip('/')}/api/v1/auth/reset-password?token={raw_token}"
    await _send_reset_email(user.email, reset_url)


async def reset_password(session: AsyncSession, payload: PasswordResetRequest) -> bool:
    token = await session.scalar(
        select(PasswordResetToken).where(PasswordResetToken.token_hash == hash_token(payload.token))
    )
    now = datetime.now(UTC)
    if token is None or token.used_at is not None or token.expires_at <= now:
        return False
    user = await session.get(User, token.user_id)
    if user is None or not user.is_active:
        return False
    user.password_hash = hash_password(payload.password)
    token.used_at = now
    await session.commit()
    return True


async def _send_reset_email(recipient: str, reset_url: str) -> None:
    if settings.brevo_api_key and settings.brevo_from_email:
        await _send_brevo_email(recipient, reset_url)
        return
    if not settings.smtp_host or not settings.smtp_from_email:
        logger.warning("Password reset email not configured; reset URL generated for %s", recipient)
        return

    message = EmailMessage()
    message["Subject"] = "Redefinição de senha — Pizzaria Campy"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        "Solicitamos a redefinição da sua senha. Acesse o link abaixo em até "
        f"{settings.password_reset_expire_minutes} minutos:\n\n{reset_url}\n"
    )

    def send() -> None:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=15) as server:
            if settings.smtp_use_tls:
                server.starttls()
            if settings.smtp_username and settings.smtp_password:
                server.login(settings.smtp_username, settings.smtp_password.replace(" ", ""))
            server.send_message(message)

    await asyncio.to_thread(send)


async def _send_brevo_email(recipient: str, reset_url: str) -> None:
    text_content = (
        "Solicitamos a redefinição da sua senha. Acesse o link abaixo em até "
        f"{settings.password_reset_expire_minutes} minutos:\n\n{reset_url}\n"
    )
    html_content = (
        "<p>Solicitamos a redefinição da sua senha.</p>"
        f"<p>Acesse o link abaixo em até {settings.password_reset_expire_minutes} minutos:</p>"
        f'<p><a href="{reset_url}">Redefinir minha senha</a></p>'
    )
    payload = {
        "sender": {
            "email": settings.brevo_from_email,
            "name": settings.brevo_from_name,
        },
        "to": [{"email": recipient}],
        "subject": "Redefinição de senha — Pizzaria Campy",
        "textContent": text_content,
        "htmlContent": html_content,
    }
    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.post(
            "https://api.brevo.com/v3/smtp/email",
            headers={"accept": "application/json", "api-key": settings.brevo_api_key},
            json=payload,
        )
        response.raise_for_status()
