from contextlib import asynccontextmanager
import logging
from pathlib import Path
from time import perf_counter
from uuid import uuid4

from fastapi import FastAPI
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.api.routes.auth import web_router
from app.core.config import settings
from app.core.rate_limit import auth_rate_limiter
from app.core.observability import configure_logging, request_metrics


logger = logging.getLogger(__name__)
configure_logging()


@asynccontextmanager
async def lifespan(application: FastAPI):
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    debug=settings.debug,
    lifespan=lifespan,
)
UPLOAD_DIR = Path("/app/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.middleware("http")
async def security_middleware(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID")
    if not request_id or len(request_id) > 100:
        request_id = str(uuid4())
    request.state.request_id = request_id
    started = perf_counter()
    if request.url.path.startswith(f"{settings.api_v1_prefix}/auth/"):
        client_host = request.client.host if request.client else "unknown"
        allowed, retry_after = auth_rate_limiter.allow(f"{client_host}:{request.url.path}")
        if not allowed:
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many authentication attempts. Try again later."},
                headers={"Retry-After": str(retry_after), "X-Request-ID": request_id},
            )
    try:
        response = await call_next(request)
    except Exception:
        request_metrics["5xx"] += 1
        raise
    duration_ms = round((perf_counter() - started) * 1000, 2)
    request_metrics["requests"] += 1
    request_metrics[f"status_{response.status_code}"] += 1
    logger.info(
        "request completed",
        extra={"request_id": request_id, "method": request.method, "path": request.url.path, "status_code": response.status_code, "duration_ms": duration_ms},
    )
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Cache-Control"] = "no-store"
    return response


@app.exception_handler(Exception)
async def unhandled_exception(request: Request, error: Exception) -> JSONResponse:
    request_id = getattr(request.state, "request_id", "unknown")
    logger.exception("unhandled API error", extra={"request_id": request_id})
    return JSONResponse(status_code=500, content={"detail": "Internal server error", "request_id": request_id}, headers={"X-Request-ID": request_id})


app.include_router(api_router, prefix=settings.api_v1_prefix)
app.include_router(web_router)
