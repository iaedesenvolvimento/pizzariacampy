from uuid import UUID

from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_current_user
from app.dependencies.auth import get_admin_user
from app.models.order import Order, Payment
from app.models.user import User
from app.schemas.orders import PaymentResponse
from app.schemas.payments import MercadoPagoPixResponse, PaymentMethodResponse, PaymentProofRequest, PaymentReviewRequest
from app.services.payments import payment_processor
from app.services.mercado_pago import (
    MercadoPagoError,
    create_pix_payment,
    get_payment,
    payment_status,
    valid_webhook_signature,
)


router = APIRouter(prefix="/payments")
admin_router = APIRouter(prefix="/admin/payments")
UPLOAD_DIR = Path("/app/uploads")
MAX_PROOF_SIZE = 10 * 1024 * 1024
ALLOWED_PROOF_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "application/pdf": ".pdf"}


@router.get("/methods", response_model=list[PaymentMethodResponse])
async def list_payment_methods() -> list[PaymentMethodResponse]:
    return [
        PaymentMethodResponse(
            method="PIX",
            title="PIX",
            description="Pagamento manual com conferência da pizzaria.",
            requires_proof=True,
            collects_card_data=False,
        ),
        PaymentMethodResponse(
            method="CASH",
            title="Dinheiro",
            description="Pagamento na retirada ou entrega, com opção de troco.",
            requires_proof=False,
            collects_card_data=False,
        ),
        PaymentMethodResponse(
            method="CARD_ON_DELIVERY",
            title="Cartão na entrega/retirada",
            description="Pagamento presencial. Nenhum dado do cartão é coletado no app.",
            requires_proof=False,
            collects_card_data=False,
        ),
    ]


@router.post("/orders/{order_id}/mercadopago/pix", response_model=MercadoPagoPixResponse)
async def create_mercado_pago_pix(
    order_id: UUID,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> MercadoPagoPixResponse:
    order = await session.scalar(select(Order).where(Order.id == order_id, Order.user_id == current_user.id))
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    if order.payment_method != "PIX":
        raise HTTPException(status_code=422, detail="Order is not paid by PIX")
    payment = await session.scalar(
        select(Payment).where(Payment.order_id == order_id).order_by(Payment.created_at.desc())
    )
    if payment is None:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.external_id and payment.provider == "MERCADO_PAGO":
        return MercadoPagoPixResponse(
            payment_id=payment.external_id,
            status=payment.status,
            qr_code=payment.qr_code,
            qr_code_base64=payment.qr_code_base64,
        )
    try:
        data = await create_pix_payment(
            order_id=order.id,
            order_number=order.order_number,
            amount=payment.amount,
            payer_email=current_user.email,
        )
    except MercadoPagoError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error
    transaction = data.get("point_of_interaction", {}).get("transaction_data", {})
    payment.provider = "MERCADO_PAGO"
    payment.external_id = str(data.get("id"))
    payment.status = payment_status(str(data.get("status", "pending")))
    payment.qr_code = transaction.get("qr_code")
    payment.qr_code_base64 = transaction.get("qr_code_base64")
    order.payment_status = payment.status
    await session.commit()
    return MercadoPagoPixResponse(
        payment_id=payment.external_id,
        status=payment.status,
        qr_code=payment.qr_code,
        qr_code_base64=payment.qr_code_base64,
        ticket_url=transaction.get("ticket_url"),
    )


@router.post("/mercadopago/webhook", status_code=204)
async def mercado_pago_webhook(request: Request, session: AsyncSession = Depends(get_session)) -> None:
    payload = await request.json()
    payment_id = str((payload.get("data") or {}).get("id") or request.query_params.get("data.id") or "")
    event_type = str(payload.get("type") or request.query_params.get("type") or "")
    if event_type != "payment" or not payment_id:
        return
    if not valid_webhook_signature(
        signature=request.headers.get("x-signature"),
        request_id=request.headers.get("x-request-id"),
        payment_id=payment_id,
    ):
        raise HTTPException(status_code=401, detail="Invalid webhook signature")
    payment = await session.scalar(select(Payment).where(Payment.external_id == payment_id))
    if payment is None:
        return
    try:
        data = await get_payment(payment_id)
    except MercadoPagoError:
        return
    payment.status = payment_status(str(data.get("status", "pending")))
    order = await session.get(Order, payment.order_id)
    if order is not None:
        order.payment_status = payment.status
    await session.commit()


@router.post("/orders/{order_id}/proof", response_model=PaymentResponse)
async def submit_pix_proof(
    order_id: UUID,
    payload: PaymentProofRequest,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> Payment:
    order = await session.scalar(select(Order).where(Order.id == order_id, Order.user_id == current_user.id))
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.payment_method != "PIX":
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Order is not paid by PIX")
    payment = await session.scalar(
        select(Payment).where(Payment.order_id == order_id).order_by(Payment.created_at.desc())
    )
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    payment.proof_url = str(payload.proof_url)
    payment.status = "UNDER_REVIEW"
    order.payment_status = "UNDER_REVIEW"
    await session.commit()
    await session.refresh(payment)
    return payment


@router.post("/orders/{order_id}/proof/upload", response_model=PaymentResponse)
async def upload_pix_proof(
    order_id: UUID,
    proof: UploadFile = File(...),
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> Payment:
    order = await session.scalar(select(Order).where(Order.id == order_id, Order.user_id == current_user.id))
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    if order.payment_method != "PIX":
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Order is not paid by PIX")
    extension = ALLOWED_PROOF_TYPES.get(proof.content_type or "")
    if extension is None:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Only JPG, PNG or PDF files are accepted")
    content = await proof.read(MAX_PROOF_SIZE + 1)
    if len(content) > MAX_PROOF_SIZE:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="File must be at most 10 MB")
    payment = await session.scalar(select(Payment).where(Payment.order_id == order_id).order_by(Payment.created_at.desc()))
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    filename = f"{uuid4().hex}{extension}"
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    (UPLOAD_DIR / filename).write_bytes(content)
    payment.proof_url = f"/uploads/{filename}"
    payment.status = "UNDER_REVIEW"
    order.payment_status = "UNDER_REVIEW"
    await session.commit()
    await session.refresh(payment)
    return payment


@admin_router.patch("/{payment_id}/review", response_model=PaymentResponse)
async def review_payment(
    payment_id: UUID,
    payload: PaymentReviewRequest,
    session: AsyncSession = Depends(get_session),
    reviewer: User = Depends(get_admin_user),
) -> Payment:
    payment = await session.scalar(select(Payment).where(Payment.id == payment_id))
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    order = await session.get(Order, payment.order_id)
    if order is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    payment.status = payload.status
    payment.reviewed_by = reviewer.id
    payment.reviewed_at = datetime.now(timezone.utc)
    payment.notes = payload.notes
    order.payment_status = payload.status
    await session.commit()
    await session.refresh(payment)
    return payment
