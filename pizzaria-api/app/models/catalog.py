from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Boolean, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint, text
from sqlalchemy.dialects.postgresql import UUID as PostgreSQLUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import TimestampedModel

if TYPE_CHECKING:
    from app.models.user import User


class Category(TimestampedModel):
    __tablename__ = "categories"

    name: Mapped[str] = mapped_column(String(80), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), nullable=False, unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    products: Mapped[list["Product"]] = relationship(back_populates="category")


class Product(TimestampedModel):
    __tablename__ = "products"

    category_id: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True), ForeignKey("categories.id", ondelete="RESTRICT"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    slug: Mapped[str] = mapped_column(String(140), nullable=False, unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    product_type: Mapped[str] = mapped_column(String(20), nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    category: Mapped[Category] = relationship(back_populates="products")
    sizes: Mapped[list["ProductSize"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )


class ProductSize(TimestampedModel):
    __tablename__ = "product_sizes"
    __table_args__ = (UniqueConstraint("product_id", "slug", name="uq_product_sizes_product_slug"),)

    product_id: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True), ForeignKey("products.id", ondelete="RESTRICT"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(60), nullable=False)
    slug: Mapped[str] = mapped_column(String(80), nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    slices: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("8"))
    max_flavors: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    product: Mapped[Product] = relationship(back_populates="sizes")
    flavor_prices: Mapped[list["FlavorSizePrice"]] = relationship(
        back_populates="product_size", cascade="all, delete-orphan"
    )
    configurations: Mapped[list["PizzaConfiguration"]] = relationship(
        back_populates="product_size", cascade="all, delete-orphan", order_by="PizzaConfiguration.display_order"
    )


class PizzaConfiguration(TimestampedModel):
    __tablename__ = "pizza_configurations"
    __table_args__ = (
        UniqueConstraint(
            "product_size_id", "flavor_count", name="uq_pizza_configurations_size_flavor_count"
        ),
    )

    product_size_id: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True), ForeignKey("product_sizes.id", ondelete="RESTRICT"), nullable=False
    )
    flavor_count: Mapped[int] = mapped_column(Integer, nullable=False)
    display_name: Mapped[str] = mapped_column(String(100), nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("0"))
    pricing_rule: Mapped[str] = mapped_column(
        String(30), nullable=False, server_default=text("'MAX_FLAVOR_PRICE'")
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    product_size: Mapped[ProductSize] = relationship(back_populates="configurations")


class Flavor(TimestampedModel):
    __tablename__ = "flavors"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    prices: Mapped[list["FlavorSizePrice"]] = relationship(
        back_populates="flavor", cascade="all, delete-orphan"
    )


class FlavorSizePrice(TimestampedModel):
    __tablename__ = "flavor_size_prices"
    __table_args__ = (UniqueConstraint("flavor_id", "product_size_id", name="uq_flavor_size_price"),)

    flavor_id: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True), ForeignKey("flavors.id", ondelete="RESTRICT"), nullable=False
    )
    product_size_id: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True), ForeignKey("product_sizes.id", ondelete="RESTRICT"), nullable=False
    )
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    flavor: Mapped[Flavor] = relationship(back_populates="prices")
    product_size: Mapped[ProductSize] = relationship(back_populates="flavor_prices")


class Edge(TimestampedModel):
    __tablename__ = "edges"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


class Extra(TimestampedModel):
    __tablename__ = "extras"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
