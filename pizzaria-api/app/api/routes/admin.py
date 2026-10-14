from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.catalog import Category, Edge, Extra, Flavor, Product, ProductSize
from app.models.order import Order
from app.models.user import User
from app.models.store_settings import StoreSettings
from app.schemas.admin import AdminCustomerResponse, AdminDashboardResponse, AdminImageUploadResponse, AdminOrderSummary, StoreSettingsResponse, StoreSettingsUpdate
from app.core.config import settings


router = APIRouter(prefix="/admin")


@router.post("/images/upload", response_model=AdminImageUploadResponse)
async def upload_catalog_image(
    file: UploadFile = File(...),
    _: User = Depends(get_admin_user),
) -> AdminImageUploadResponse:
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp"}
    extension = Path(file.filename or "").suffix.lower()
    if file.content_type not in allowed_types and extension not in allowed_extensions:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Use uma imagem JPG, PNG ou WebP.",
        )
    content = await file.read()
    if len(content) > 8 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="A imagem deve ter no máximo 8 MB.",
        )
    if not all(
        (settings.cloudinary_cloud_name, settings.cloudinary_api_key, settings.cloudinary_api_secret)
    ):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Cloudinary não está configurado na API.",
        )
    try:
        import cloudinary
        import cloudinary.uploader
        from io import BytesIO

        cloudinary.config(
            cloud_name=settings.cloudinary_cloud_name,
            api_key=settings.cloudinary_api_key,
            api_secret=settings.cloudinary_api_secret,
            secure=True,
        )
        result = cloudinary.uploader.upload(
            BytesIO(content),
            folder=settings.cloudinary_upload_folder,
            resource_type="image",
        )
    except Exception as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Não foi possível enviar a imagem ao Cloudinary.",
        ) from error
    return AdminImageUploadResponse(
        image_url=str(result["secure_url"]),
        public_id=str(result["public_id"]),
    )


@router.get("/customers", response_model=list[AdminCustomerResponse])
async def list_customers(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[AdminCustomerResponse]:
    result = await session.scalars(
        select(User).where(User.role == "CUSTOMER").order_by(User.name, User.email)
    )
    return [
        AdminCustomerResponse(
            id=str(customer.id),
            name=customer.name,
            email=customer.email,
            is_active=customer.is_active,
            created_at=customer.created_at,
        )
        for customer in result
    ]


@router.get("/settings", response_model=StoreSettingsResponse)
async def get_store_settings(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> StoreSettings:
    settings = await session.scalar(select(StoreSettings).order_by(StoreSettings.created_at).limit(1))
    if settings is None:
        settings = StoreSettings(store_name="Pizzaria Campy")
        session.add(settings)
        await session.commit()
        await session.refresh(settings)
    return settings


@router.patch("/settings", response_model=StoreSettingsResponse)
async def update_store_settings(
    payload: StoreSettingsUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> StoreSettings:
    settings = await get_store_settings(session, _)
    for field, value in payload.model_dump().items():
        setattr(settings, field, value.strip())
    await session.commit()
    await session.refresh(settings)
    return settings


async def _count(session: AsyncSession, model: type, *, active_only: bool = False) -> int:
    statement = select(func.count()).select_from(model)
    if active_only:
        statement = statement.where(model.is_active.is_(True))
    return int(await session.scalar(statement) or 0)


@router.get("/dashboard", response_model=AdminDashboardResponse)
async def get_dashboard(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> AdminDashboardResponse:
    pending_statuses = {"PENDING", "CONFIRMED"}
    pending_orders = int(
        await session.scalar(select(func.count()).select_from(Order).where(Order.status.in_(pending_statuses))) or 0
    )
    preparing_orders = int(
        await session.scalar(select(func.count()).select_from(Order).where(Order.status == "PREPARING")) or 0
    )
    ready_orders = int(
        await session.scalar(select(func.count()).select_from(Order).where(Order.status == "READY")) or 0
    )
    recent = await session.scalars(
        select(Order).options(selectinload(Order.payments)).order_by(Order.created_at.desc()).limit(10)
    )
    recent_orders = [
        AdminOrderSummary(
            id=str(order.id),
            order_number=order.order_number,
            status=order.status,
            fulfillment_type=order.fulfillment_type,
            total_amount=order.total_amount,
            created_at=order.created_at,
            payment_id=str(order.payments[-1].id) if order.payments else None,
            payment_status=order.payments[-1].status if order.payments else None,
            proof_url=order.payments[-1].proof_url if order.payments else None,
        )
        for order in recent
    ]
    return AdminDashboardResponse(
        pending_orders=pending_orders,
        preparing_orders=preparing_orders,
        ready_orders=ready_orders,
        active_products=await _count(session, Product, active_only=True),
        active_categories=await _count(session, Category, active_only=True),
        active_flavors=await _count(session, Flavor, active_only=True),
        active_sizes=await _count(session, ProductSize, active_only=True),
        active_edges=await _count(session, Edge, active_only=True),
        active_extras=await _count(session, Extra, active_only=True),
        customers=int(await session.scalar(select(func.count()).select_from(User).where(User.role == "CUSTOMER")) or 0),
        recent_orders=recent_orders,
    )
