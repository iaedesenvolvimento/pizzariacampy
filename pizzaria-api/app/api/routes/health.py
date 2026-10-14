from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session


router = APIRouter()


@router.get("/health", summary="Verifica se a aplicação está disponível")
async def health_check() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/ready", summary="Verifica se a aplicação pode acessar o banco")
async def readiness_check(session: AsyncSession = Depends(get_session)) -> dict[str, str]:
    try:
        await session.execute(text("SELECT 1"))
    except Exception as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database is not ready",
        ) from error

    return {"status": "ready"}
