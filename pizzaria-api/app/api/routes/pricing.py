from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.schemas.pricing import PricingQuoteRequest, PricingQuoteResponse
from app.services.pricing import PricingError, calculate_quote


router = APIRouter(prefix="/pricing")


def pricing_error_response(error: PricingError) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail={"code": error.code, "message": error.message},
    )


@router.post("/quote", response_model=PricingQuoteResponse)
async def quote(
    request: PricingQuoteRequest,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
) -> PricingQuoteResponse:
    if request.fulfillment_type == "DELIVERY":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "DELIVERY_FEE_RESOLUTION_REQUIRED",
                "message": "Delivery fee must be resolved from the delivery zone before quoting.",
            },
        )
    try:
        return await calculate_quote(session, request, user_id=current_user.id)
    except PricingError as error:
        raise pricing_error_response(error) from error
