from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class CatalogBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    slug: str = Field(min_length=1, max_length=100, pattern=r"^[a-z0-9-]+$")
    description: str | None = None
    sort_order: int = Field(default=0, ge=0)


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    slug: str | None = Field(default=None, min_length=1, max_length=100, pattern=r"^[a-z0-9-]+$")
    description: str | None = None
    sort_order: int | None = Field(default=None, ge=0)
    is_active: bool | None = None


class CategoryResponse(CatalogBase):
    id: UUID
    name: str
    slug: str
    description: str | None
    sort_order: int
    is_active: bool


class ProductCreate(BaseModel):
    category_id: UUID
    name: str = Field(min_length=1, max_length=120)
    slug: str = Field(min_length=1, max_length=140, pattern=r"^[a-z0-9-]+$")
    description: str | None = None
    product_type: str = Field(pattern=r"^(PIZZA|BEVERAGE|DESSERT|COMBO)$")
    image_url: str | None = None
    sort_order: int = Field(default=0, ge=0)


class ProductUpdate(BaseModel):
    category_id: UUID | None = None
    name: str | None = Field(default=None, min_length=1, max_length=120)
    slug: str | None = Field(default=None, min_length=1, max_length=140, pattern=r"^[a-z0-9-]+$")
    description: str | None = None
    product_type: str | None = Field(default=None, pattern=r"^(PIZZA|BEVERAGE|DESSERT|COMBO)$")
    image_url: str | None = None
    sort_order: int | None = Field(default=None, ge=0)
    is_active: bool | None = None


class ProductResponse(CatalogBase):
    id: UUID
    category_id: UUID
    name: str
    slug: str
    description: str | None
    product_type: str
    image_url: str | None
    sort_order: int
    is_active: bool


class ProductSizeCreate(BaseModel):
    name: str = Field(min_length=1, max_length=60)
    slug: str = Field(min_length=1, max_length=80, pattern=r"^[a-z0-9-]+$")
    price: Decimal = Field(ge=0, decimal_places=2)
    slices: int = Field(default=8, ge=1)
    max_flavors: int = Field(ge=1)


class ProductSizeResponse(CatalogBase):
    id: UUID
    product_id: UUID
    name: str
    slug: str
    price: Decimal
    slices: int
    max_flavors: int
    is_active: bool


class ProductSizeUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=60)
    slug: str | None = Field(default=None, min_length=1, max_length=80, pattern=r"^[a-z0-9-]+$")
    price: Decimal | None = Field(default=None, ge=0, decimal_places=2)
    slices: int | None = Field(default=None, ge=1)
    max_flavors: int | None = Field(default=None, ge=1)
    is_active: bool | None = None


class PizzaConfigurationCreate(BaseModel):
    flavor_count: int = Field(ge=1, le=10)
    display_name: str = Field(min_length=1, max_length=100)
    display_order: int = Field(default=0, ge=0)
    pricing_rule: str = Field(default="MAX_FLAVOR_PRICE", pattern=r"^(MAX_FLAVOR_PRICE|AVERAGE_FLAVOR_PRICE)$")


class PizzaConfigurationUpdate(BaseModel):
    flavor_count: int | None = Field(default=None, ge=1, le=10)
    display_name: str | None = Field(default=None, min_length=1, max_length=100)
    display_order: int | None = Field(default=None, ge=0)
    pricing_rule: str | None = Field(
        default=None, pattern=r"^(MAX_FLAVOR_PRICE|AVERAGE_FLAVOR_PRICE)$"
    )
    is_active: bool | None = None


class PizzaConfigurationResponse(CatalogBase):
    id: UUID
    product_size_id: UUID
    flavor_count: int
    display_name: str
    display_order: int
    pricing_rule: str
    is_active: bool


class FlavorCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str | None = None
    image_url: str | None = None


class FlavorUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    description: str | None = None
    image_url: str | None = None
    is_active: bool | None = None


class FlavorResponse(CatalogBase):
    id: UUID
    name: str
    description: str | None
    image_url: str | None
    is_active: bool


class FlavorSizePriceCreate(BaseModel):
    flavor_id: UUID
    product_size_id: UUID
    price: Decimal = Field(ge=0, decimal_places=2)


class FlavorSizePriceResponse(CatalogBase):
    id: UUID
    flavor_id: UUID
    product_size_id: UUID
    price: Decimal


class FlavorSizePriceUpdate(BaseModel):
    price: Decimal = Field(ge=0, decimal_places=2)


class ProductFlavorSelectionUpdate(BaseModel):
    flavor_ids: list[UUID] = Field(min_length=1)


class PricedOptionCreate(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    price: Decimal = Field(ge=0, decimal_places=2)


class PricedOptionUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    price: Decimal | None = Field(default=None, ge=0, decimal_places=2)
    is_active: bool | None = None


class PricedOptionResponse(CatalogBase):
    id: UUID
    name: str
    price: Decimal
    is_active: bool


class ProductOptionsResponse(BaseModel):
    product: ProductResponse
    sizes: list[ProductSizeResponse]
    configurations: list[PizzaConfigurationResponse]
    flavors: list[FlavorResponse]
    flavor_prices: list[FlavorSizePriceResponse]
    edges: list[PricedOptionResponse]
    extras: list[PricedOptionResponse]
