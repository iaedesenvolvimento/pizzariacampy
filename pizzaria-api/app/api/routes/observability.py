from fastapi import APIRouter

from app.core.observability import request_metrics


router = APIRouter()


@router.get("/metrics", include_in_schema=False)
async def metrics() -> dict[str, int]:
    return dict(request_metrics)
