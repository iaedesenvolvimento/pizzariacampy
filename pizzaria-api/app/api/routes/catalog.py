from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.dependencies.auth import get_admin_user
from app.models.catalog import (
    Category,
    Edge,
    Extra,
    Flavor,
    FlavorSizePrice,
    Product,
    ProductSize,
)
from app.models.user import User
from app.schemas.catalog import (
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    FlavorCreate,
    FlavorResponse,
    FlavorSizePriceCreate,
    FlavorSizePriceResponse,
    FlavorSizePriceUpdate,
    FlavorUpdate,
    PricedOptionCreate,
    PricedOptionResponse,
    PricedOptionUpdate,
    ProductCreate,
    ProductOptionsResponse,
    ProductResponse,
    ProductSizeCreate,
    ProductSizeResponse,
    ProductSizeUpdate,
    ProductUpdate,
)


router = APIRouter()
admin_router = APIRouter(prefix="/admin/catalog")


@admin_router.get("/categories", response_model=list[CategoryResponse])
async def list_admin_categories(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[Category]:
    result = await session.scalars(select(Category).order_by(Category.sort_order, Category.name))
    return list(result)


@admin_router.get("/products", response_model=list[ProductResponse])
async def list_admin_products(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[Product]:
    result = await session.scalars(select(Product).order_by(Product.sort_order, Product.name))
    return list(result)


@admin_router.get("/flavors", response_model=list[FlavorResponse])
async def list_admin_flavors(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[Flavor]:
    return list(await session.scalars(select(Flavor).order_by(Flavor.name)))


@admin_router.get("/edges", response_model=list[PricedOptionResponse])
async def list_admin_edges(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[Edge]:
    return list(await session.scalars(select(Edge).order_by(Edge.name)))


@admin_router.get("/extras", response_model=list[PricedOptionResponse])
async def list_admin_extras(
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[Extra]:
    return list(await session.scalars(select(Extra).order_by(Extra.name)))


async def get_active_category(session: AsyncSession, category_id: UUID) -> Category:
    category = await session.get(Category, category_id)
    if category is None or not category.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    return category


@router.get("/categories", response_model=list[CategoryResponse])
async def list_categories(session: AsyncSession = Depends(get_session)) -> list[Category]:
    result = await session.scalars(
        select(Category)
        .where(Category.is_active.is_(True))
        .order_by(Category.sort_order, Category.name)
    )
    return list(result)


@router.get("/products", response_model=list[ProductResponse])
async def list_products(
    category_id: UUID | None = None,
    search: str | None = Query(default=None, min_length=1, max_length=100),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    session: AsyncSession = Depends(get_session),
) -> list[Product]:
    statement = select(Product).where(Product.is_active.is_(True))
    if category_id is not None:
        statement = statement.where(Product.category_id == category_id)
    if search:
        statement = statement.where(Product.name.ilike(f"%{search}%"))
    result = await session.scalars(statement.order_by(Product.sort_order, Product.name).limit(limit).offset(offset))
    return list(result)


@router.get("/products/{product_id}", response_model=ProductResponse)
async def get_product(product_id: UUID, session: AsyncSession = Depends(get_session)) -> Product:
    product = await session.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product


@router.get("/products/{product_id}/options", response_model=ProductOptionsResponse)
async def get_product_options(
    product_id: UUID,
    session: AsyncSession = Depends(get_session),
) -> ProductOptionsResponse:
    product = await session.get(Product, product_id)
    if product is None or not product.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    sizes = list(
        await session.scalars(
            select(ProductSize)
            .where(ProductSize.product_id == product_id, ProductSize.is_active.is_(True))
            .order_by(ProductSize.name)
        )
    )
    is_pizza = product.product_type == "PIZZA"
    flavors = []
    if is_pizza and sizes:
        flavors = list(
            await session.scalars(
                select(Flavor)
                .join(FlavorSizePrice, FlavorSizePrice.flavor_id == Flavor.id)
                .where(
                    Flavor.is_active.is_(True),
                    FlavorSizePrice.product_size_id.in_([size.id for size in sizes]),
                )
                .distinct()
                .order_by(Flavor.name)
            )
        )
    flavor_prices = list(
        await session.scalars(
            select(FlavorSizePrice)
            .where(FlavorSizePrice.product_size_id.in_([size.id for size in sizes]))
            .order_by(FlavorSizePrice.price)
        )
    ) if sizes else []
    edges = list(await session.scalars(select(Edge).where(Edge.is_active.is_(True)).order_by(Edge.name))) if is_pizza else []
    extras = list(await session.scalars(select(Extra).where(Extra.is_active.is_(True)).order_by(Extra.name))) if is_pizza else []
    return ProductOptionsResponse(
        product=product,
        sizes=sizes,
        flavors=flavors,
        flavor_prices=flavor_prices,
        edges=edges,
        extras=extras,
    )


@admin_router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    payload: CategoryCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Category:
    existing = await session.scalar(select(Category).where(Category.slug == payload.slug))
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe uma categoria com este slug.",
        )
    category = Category(**payload.model_dump())
    session.add(category)
    await session.commit()
    await session.refresh(category)
    return category


@admin_router.patch("/categories/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: UUID,
    payload: CategoryUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Category:
    category = await session.get(Category, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    values = payload.model_dump(exclude_unset=True)
    if "slug" in values:
        existing = await session.scalar(
            select(Category).where(Category.slug == values["slug"], Category.id != category_id)
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Já existe uma categoria com este slug.",
            )
    for field, value in values.items():
        setattr(category, field, value)
    await session.commit()
    await session.refresh(category)
    return category


@admin_router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: UUID,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> None:
    category = await session.get(Category, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    try:
        await session.delete(category)
        await session.commit()
    except IntegrityError as error:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A categoria possui produtos ou pedidos relacionados. Desative-a em vez de excluir.",
        ) from error


@admin_router.post("/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    payload: ProductCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Product:
    await get_active_category(session, payload.category_id)
    existing = await session.scalar(select(Product).where(Product.slug == payload.slug))
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe um produto com este slug.",
        )
    product = Product(**payload.model_dump())
    session.add(product)
    await session.commit()
    await session.refresh(product)
    return product


@admin_router.patch("/products/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: UUID,
    payload: ProductUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Product:
    product = await session.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    values = payload.model_dump(exclude_unset=True)
    if "slug" in values:
        existing = await session.scalar(
            select(Product).where(Product.slug == values["slug"], Product.id != product_id)
        )
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Já existe um produto com este slug.",
            )
    if "category_id" in values:
        await get_active_category(session, values["category_id"])
    for field, value in values.items():
        setattr(product, field, value)
    await session.commit()
    await session.refresh(product)
    return product


@admin_router.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> None:
    product = await session.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    try:
        await session.delete(product)
        await session.commit()
    except IntegrityError as error:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="O produto possui tamanhos, pedidos ou outras referências. Desative-o em vez de excluir.",
        ) from error


@admin_router.post("/products/{product_id}/sizes", response_model=ProductSizeResponse, status_code=status.HTTP_201_CREATED)
async def create_product_size(
    product_id: UUID,
    payload: ProductSizeCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> ProductSize:
    product = await session.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    size = ProductSize(product_id=product_id, **payload.model_dump())
    session.add(size)
    await session.commit()
    await session.refresh(size)
    return size


@admin_router.get("/products/{product_id}/sizes", response_model=list[ProductSizeResponse])
async def list_product_sizes(
    product_id: UUID,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[ProductSize]:
    product = await session.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    result = await session.scalars(
        select(ProductSize).where(ProductSize.product_id == product_id).order_by(ProductSize.name)
    )
    return list(result)


@admin_router.patch("/sizes/{size_id}", response_model=ProductSizeResponse)
async def update_product_size(
    size_id: UUID,
    payload: ProductSizeUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> ProductSize:
    size = await session.get(ProductSize, size_id)
    if size is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Size not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(size, field, value)
    await session.commit()
    await session.refresh(size)
    return size


@admin_router.post("/flavors", response_model=FlavorResponse, status_code=status.HTTP_201_CREATED)
async def create_flavor(
    payload: FlavorCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Flavor:
    flavor = Flavor(**payload.model_dump())
    session.add(flavor)
    await session.commit()
    await session.refresh(flavor)
    return flavor


@admin_router.patch("/flavors/{flavor_id}", response_model=FlavorResponse)
async def update_flavor(
    flavor_id: UUID,
    payload: FlavorUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Flavor:
    flavor = await session.get(Flavor, flavor_id)
    if flavor is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flavor not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(flavor, field, value)
    await session.commit()
    await session.refresh(flavor)
    return flavor


@admin_router.post("/flavor-prices", response_model=FlavorSizePriceResponse, status_code=status.HTTP_201_CREATED)
async def create_flavor_price(
    payload: FlavorSizePriceCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FlavorSizePrice:
    flavor = await session.get(Flavor, payload.flavor_id)
    size = await session.get(ProductSize, payload.product_size_id)
    if flavor is None or size is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flavor or size not found")
    existing = await session.scalar(
        select(FlavorSizePrice).where(
            FlavorSizePrice.flavor_id == payload.flavor_id,
            FlavorSizePrice.product_size_id == payload.product_size_id,
        )
    )
    if existing is not None:
        existing.price = payload.price
        await session.commit()
        await session.refresh(existing)
        return existing
    flavor_price = FlavorSizePrice(**payload.model_dump())
    session.add(flavor_price)
    await session.commit()
    await session.refresh(flavor_price)
    return flavor_price


@admin_router.get("/flavor-prices", response_model=list[FlavorSizePriceResponse])
async def list_flavor_prices(
    flavor_id: UUID | None = Query(default=None),
    product_size_id: UUID | None = Query(default=None),
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> list[FlavorSizePrice]:
    query = select(FlavorSizePrice).order_by(FlavorSizePrice.created_at)
    if flavor_id is not None:
        query = query.where(FlavorSizePrice.flavor_id == flavor_id)
    if product_size_id is not None:
        query = query.where(FlavorSizePrice.product_size_id == product_size_id)
    result = await session.scalars(query)
    return list(result)


@admin_router.patch("/flavor-prices/{price_id}", response_model=FlavorSizePriceResponse)
async def update_flavor_price(
    price_id: UUID,
    payload: FlavorSizePriceUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> FlavorSizePrice:
    price = await session.get(FlavorSizePrice, price_id)
    if price is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Flavor price not found")
    price.price = payload.price
    await session.commit()
    await session.refresh(price)
    return price


async def create_priced_option(
    model: type[Edge] | type[Extra],
    payload: PricedOptionCreate,
    session: AsyncSession,
) -> Edge | Extra:
    option = model(**payload.model_dump())
    session.add(option)
    await session.commit()
    await session.refresh(option)
    return option


async def update_priced_option(
    model: type[Edge] | type[Extra],
    option_id: UUID,
    payload: PricedOptionUpdate,
    session: AsyncSession,
) -> Edge | Extra:
    option = await session.get(model, option_id)
    if option is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Option not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(option, field, value)
    await session.commit()
    await session.refresh(option)
    return option


@admin_router.post("/edges", response_model=PricedOptionResponse, status_code=status.HTTP_201_CREATED)
async def create_edge(
    payload: PricedOptionCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Edge:
    return await create_priced_option(Edge, payload, session)


@admin_router.patch("/edges/{edge_id}", response_model=PricedOptionResponse)
async def update_edge(
    edge_id: UUID,
    payload: PricedOptionUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Edge:
    return await update_priced_option(Edge, edge_id, payload, session)


@admin_router.post("/extras", response_model=PricedOptionResponse, status_code=status.HTTP_201_CREATED)
async def create_extra(
    payload: PricedOptionCreate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Extra:
    return await create_priced_option(Extra, payload, session)


@admin_router.patch("/extras/{extra_id}", response_model=PricedOptionResponse)
async def update_extra(
    extra_id: UUID,
    payload: PricedOptionUpdate,
    session: AsyncSession = Depends(get_session),
    _: User = Depends(get_admin_user),
) -> Extra:
    return await update_priced_option(Extra, extra_id, payload, session)
