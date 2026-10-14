from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_current_user
from app.models.address import CustomerAddress
from app.models.user import User
from app.schemas.addresses import AddressCreate, AddressResponse, AddressUpdate

router = APIRouter(prefix="/customer/addresses")


def _response(address: CustomerAddress) -> AddressResponse:
    return AddressResponse(id=str(address.id), label=address.label, address=address.address, neighborhood=address.neighborhood, city=address.city, complement=address.complement, is_default=address.is_default)


async def _set_default(session: AsyncSession, user_id: UUID, address_id: UUID | None = None) -> None:
    statement = update(CustomerAddress).where(CustomerAddress.user_id == user_id, CustomerAddress.is_active.is_(True)).values(is_default=False)
    if address_id is not None:
        statement = statement.where(CustomerAddress.id != address_id)
    await session.execute(statement)


@router.get("", response_model=list[AddressResponse])
async def list_addresses(session: AsyncSession = Depends(get_session), user: User = Depends(get_current_user)) -> list[AddressResponse]:
    result = await session.scalars(select(CustomerAddress).where(CustomerAddress.user_id == user.id, CustomerAddress.is_active.is_(True)).order_by(CustomerAddress.is_default.desc(), CustomerAddress.created_at.desc()))
    return [_response(address) for address in result]


@router.post("", response_model=AddressResponse, status_code=status.HTTP_201_CREATED)
async def create_address(payload: AddressCreate, session: AsyncSession = Depends(get_session), user: User = Depends(get_current_user)) -> AddressResponse:
    if payload.is_default:
        await _set_default(session, user.id)
    address = CustomerAddress(user_id=user.id, **payload.model_dump())
    session.add(address)
    await session.commit()
    await session.refresh(address)
    return _response(address)


@router.patch("/{address_id}", response_model=AddressResponse)
async def update_address(address_id: UUID, payload: AddressUpdate, session: AsyncSession = Depends(get_session), user: User = Depends(get_current_user)) -> AddressResponse:
    address = await session.scalar(select(CustomerAddress).where(CustomerAddress.id == address_id, CustomerAddress.user_id == user.id, CustomerAddress.is_active.is_(True)))
    if address is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    if payload.is_default:
        await _set_default(session, user.id, address.id)
    for key, value in payload.model_dump().items():
        setattr(address, key, value)
    await session.commit()
    await session.refresh(address)
    return _response(address)


@router.delete("/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_address(address_id: UUID, session: AsyncSession = Depends(get_session), user: User = Depends(get_current_user)) -> None:
    address = await session.scalar(select(CustomerAddress).where(CustomerAddress.id == address_id, CustomerAddress.user_id == user.id, CustomerAddress.is_active.is_(True)))
    if address is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    address.is_active = False
    address.is_default = False
    await session.commit()
