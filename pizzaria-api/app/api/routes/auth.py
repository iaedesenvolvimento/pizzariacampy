from io import BytesIO
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Request, UploadFile, status
from fastapi.responses import HTMLResponse
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.config import settings
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    LogoutRequest,
    PasswordRecoveryRequest,
    PasswordResetRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
    UserUpdate,
)
from app.services.auth import (
    AuthError,
    authenticate_user,
    register_user,
    revoke_refresh_token,
    rotate_refresh_token,
)
from app.services.password_reset import request_password_reset, reset_password


router = APIRouter(prefix="/auth")
web_router = APIRouter()


def user_agent_from_request(request: Request) -> str | None:
    return request.headers.get("user-agent")


def auth_error_response(error: AuthError) -> HTTPException:
    if str(error) == "EMAIL_ALREADY_REGISTERED":
        return HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email is already registered",
        )
    if str(error) == "INVALID_CREDENTIALS":
        return HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if str(error) == "PRIVACY_CONSENT_REQUIRED":
        return HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Privacy consent is required",
        )
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid refresh token",
    )


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterRequest,
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    try:
        return await register_user(session, payload, user_agent_from_request(request))
    except AuthError as error:
        await session.rollback()
        raise auth_error_response(error) from error


@router.post("/login", response_model=TokenResponse)
async def login(
    payload: LoginRequest,
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    try:
        return await authenticate_user(session, payload, user_agent_from_request(request))
    except AuthError as error:
        await session.rollback()
        raise auth_error_response(error) from error


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    payload: RefreshRequest,
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    try:
        return await rotate_refresh_token(session, payload.refresh_token, user_agent_from_request(request))
    except AuthError as error:
        await session.rollback()
        raise auth_error_response(error) from error


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    payload: LogoutRequest,
    session: AsyncSession = Depends(get_session),
) -> None:
    await revoke_refresh_token(session, payload.refresh_token)


@router.get("/me", response_model=UserResponse)
async def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    current_user.name = payload.name.strip()
    await session.commit()
    await session.refresh(current_user)
    return current_user


@router.post("/me/avatar", response_model=UserResponse)
async def update_my_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp"}
    extension = Path(file.filename or "").suffix.lower()
    if file.content_type not in allowed_types and extension not in allowed_extensions:
        raise HTTPException(status_code=415, detail="Use uma imagem JPG, PNG ou WebP.")
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="A imagem deve ter no máximo 5 MB.")
    if not all((settings.cloudinary_cloud_name, settings.cloudinary_api_key, settings.cloudinary_api_secret)):
        raise HTTPException(status_code=503, detail="Cloudinary não está configurado na API.")
    try:
        import cloudinary
        import cloudinary.uploader

        cloudinary.config(
            cloud_name=settings.cloudinary_cloud_name,
            api_key=settings.cloudinary_api_key,
            api_secret=settings.cloudinary_api_secret,
            secure=True,
        )
        result = cloudinary.uploader.upload(
            BytesIO(content), folder="pizzaria-campy/profiles", resource_type="image"
        )
    except Exception as error:
        raise HTTPException(status_code=502, detail="Não foi possível enviar a foto.") from error
    current_user.avatar_url = str(result["secure_url"])
    await session.commit()
    await session.refresh(current_user)
    return current_user


@router.post("/password-recovery", status_code=status.HTTP_202_ACCEPTED)
async def password_recovery(
    payload: PasswordRecoveryRequest,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    await request_password_reset(session, str(payload.email))
    return {"message": "If the account exists, recovery instructions were sent."}


@router.get("/reset-password", response_class=HTMLResponse, include_in_schema=False)
async def password_reset_page(token: str = Query(default="")) -> HTMLResponse:
    escaped_token = token.replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;").replace(">", "&gt;")
    return HTMLResponse(
        f"""<!doctype html>
<html lang="pt-BR">
<head><meta name="viewport" content="width=device-width, initial-scale=1"><title>Redefinir senha</title>
<style>body{{font-family:Arial,sans-serif;background:#fffaf4;color:#2b2220;margin:0;padding:24px}}main{{max-width:420px;margin:8vh auto;background:#fff;border-radius:16px;padding:24px;box-shadow:0 4px 18px #0002}}h1{{font-size:24px;margin-top:0}}label{{display:block;margin:16px 0 6px}}input{{box-sizing:border-box;width:100%;padding:13px;border:1px solid #c9b9b3;border-radius:8px;font-size:16px}}button{{width:100%;margin-top:22px;padding:14px;border:0;border-radius:8px;background:#cc252b;color:#fff;font-weight:bold;font-size:16px}}</style></head>
<body><main><h1>Redefinir senha</h1><p>Informe uma nova senha para sua conta.</p><p>A senha deve ter no mínimo 8 caracteres, com letra maiúscula, minúscula e número.</p>
<form method="post" action="/api/v1/auth/reset-password">
<input type="hidden" name="token" value="{escaped_token}">
<label for="password">Nova senha</label><input id="password" name="password" type="password" minlength="8" required autocomplete="new-password" placeholder="Mínimo de 8 caracteres">
<button type="submit">Salvar nova senha</button></form></main></body></html>"""
    )


@router.post("/reset-password", response_class=HTMLResponse, include_in_schema=False)
async def password_reset_form(
    token: str = Form(...),
    password: str = Form(...),
    session: AsyncSession = Depends(get_session),
) -> HTMLResponse:
    try:
        payload = PasswordResetRequest(token=token, password=password)
    except ValidationError:
        return HTMLResponse(
            f"<h2>Senha inválida</h2><p>Use pelo menos 8 caracteres, incluindo uma letra maiúscula, uma minúscula e um número.</p><p><a href=\"/reset-password?token={token}\">Voltar</a></p>",
            status_code=status.HTTP_400_BAD_REQUEST,
        )
    if not await reset_password(session, payload):
        return HTMLResponse(
            "<h2>Link inválido ou expirado</h2><p>Solicite uma nova recuperação de senha.</p>",
            status_code=status.HTTP_400_BAD_REQUEST,
        )
    return HTMLResponse("<h2>Senha alterada com sucesso</h2><p>Você já pode voltar ao aplicativo e entrar com a nova senha.</p>")


web_router.add_api_route("/reset-password", password_reset_page, methods=["GET"], response_class=HTMLResponse, include_in_schema=False)
web_router.add_api_route("/reset-password", password_reset_form, methods=["POST"], response_class=HTMLResponse, include_in_schema=False)


@router.post("/password-reset", status_code=status.HTTP_204_NO_CONTENT)
async def password_reset(
    payload: PasswordResetRequest,
    session: AsyncSession = Depends(get_session),
) -> None:
    if not await reset_password(session, payload):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset token")
