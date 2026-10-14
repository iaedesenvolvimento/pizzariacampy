from pydantic import BaseModel, Field


class AddressCreate(BaseModel):
    label: str = Field(min_length=1, max_length=50)
    address: str = Field(min_length=1, max_length=500)
    neighborhood: str = Field(min_length=1, max_length=100)
    city: str = Field(min_length=1, max_length=100)
    complement: str | None = Field(default=None, max_length=150)
    is_default: bool = False


class AddressUpdate(AddressCreate):
    pass


class AddressResponse(AddressCreate):
    id: str
