import asyncio
import json
import re
import sys
from decimal import Decimal
from pathlib import Path
from typing import Any

from sqlalchemy import select


def money(value: str | float) -> Decimal:
    amount = Decimal(str(value)).quantize(Decimal("0.01"))
    if amount < 0:
        raise ValueError(f"Preço não pode ser negativo: {value}")
    return amount


SLUG_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
PRODUCT_TYPES = {"PIZZA", "BEVERAGE", "DESSERT", "COMBO"}
PLACEHOLDER_VALUES = {"nome real da pizza", "descrição real do produto", "sabor real", "borda real", "adicional real"}


def _require_text(value: Any, field: str, path: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{path}.{field} deve ser um texto preenchido")
    if value.strip().lower() in PLACEHOLDER_VALUES:
        raise ValueError(f"{path}.{field} ainda contém texto de exemplo")
    return value.strip()


def _require_slug(value: Any, field: str, path: str) -> str:
    slug = _require_text(value, field, path)
    if not SLUG_PATTERN.fullmatch(slug):
        raise ValueError(f"{path}.{field} deve usar apenas slug kebab-case")
    return slug


def _ensure_unique(values: list[str], label: str) -> None:
    duplicates = sorted({value for value in values if values.count(value) > 1})
    if duplicates:
        raise ValueError(f"{label} duplicado(s): {', '.join(duplicates)}")


def validate_catalog(payload: dict[str, Any]) -> None:
    if not isinstance(payload, dict):
        raise TypeError("O catálogo deve ser um objeto JSON")
    for key in ("categories", "products", "edges", "extras"):
        if not isinstance(payload.get(key, []), list):
            raise TypeError(f"{key} deve ser uma lista")

    categories = payload.get("categories", [])
    category_slugs = []
    for index, category in enumerate(categories):
        path = f"categories[{index}]"
        _require_text(category.get("name"), "name", path)
        category_slugs.append(_require_slug(category.get("slug"), "slug", path))
    _ensure_unique(category_slugs, "Slug de categoria")

    products = payload.get("products", [])
    product_slugs = []
    for index, product in enumerate(products):
        path = f"products[{index}]"
        _require_text(product.get("name"), "name", path)
        product_slugs.append(_require_slug(product.get("slug"), "slug", path))
        if product.get("category_slug") not in category_slugs:
            raise ValueError(f"{path}.category_slug não referencia uma categoria existente")
        if product.get("product_type") not in PRODUCT_TYPES:
            raise ValueError(f"{path}.product_type inválido")
        image_url = product.get("image_url")
        if image_url and (not isinstance(image_url, str) or "exemplo.com" in image_url):
            raise ValueError(f"{path}.image_url ainda usa uma URL de exemplo")
        sizes = product.get("sizes", [])
        if not sizes:
            raise ValueError(f"{path}.sizes deve conter pelo menos um tamanho")
        size_slugs = []
        for size_index, size in enumerate(sizes):
            size_path = f"{path}.sizes[{size_index}]"
            _require_text(size.get("name"), "name", size_path)
            size_slugs.append(_require_slug(size.get("slug"), "slug", size_path))
            if money(size.get("price")) <= 0:
                raise ValueError(f"{size_path}.price deve ser maior que zero")
            if size.get("slices", 8) != 8:
                raise ValueError(f"{size_path}.slices deve ser 8 no MVP")
            if not 1 <= size.get("max_flavors", 1) <= 4:
                raise ValueError(f"{size_path}.max_flavors deve estar entre 1 e 4")
            for flavor_index, flavor in enumerate(size.get("flavors", [])):
                flavor_path = f"{size_path}.flavors[{flavor_index}]"
                _require_text(flavor.get("name"), "name", flavor_path)
                if money(flavor.get("price", size["price"])) <= 0:
                    raise ValueError(f"{flavor_path}.price deve ser maior que zero")
        _ensure_unique(size_slugs, f"Slug de tamanho em {product['slug']}")
    _ensure_unique(product_slugs, "Slug de produto")

    for option_key in ("edges", "extras"):
        names = []
        for index, option in enumerate(payload.get(option_key, [])):
            path = f"{option_key}[{index}]"
            names.append(_require_text(option.get("name"), "name", path).lower())
            if money(option.get("price")) <= 0:
                raise ValueError(f"{path}.price deve ser maior que zero")
        _ensure_unique(names, f"Nome de {option_key}")


async def first_or_create(session, model, lookup: dict, values: dict):
    item = await session.scalar(select(model).filter_by(**lookup))
    if item is None:
        item = model(**lookup, **values)
        session.add(item)
        await session.flush()
    else:
        for field, value in values.items():
            setattr(item, field, value)
        await session.flush()
    return item


async def import_catalog(path: Path) -> None:
    from app.core.database import session_factory
    from app.models.catalog import (
        Category,
        Edge,
        Extra,
        Flavor,
        FlavorSizePrice,
        Product,
        ProductSize,
    )

    payload = json.loads(path.read_text(encoding="utf-8"))
    validate_catalog(payload)
    async with session_factory() as session:
        category_by_slug = {}
        for category_data in payload.get("categories", []):
            category = await first_or_create(
                session,
                Category,
                {"slug": category_data["slug"]},
                {
                    "name": category_data["name"],
                    "description": category_data.get("description"),
                    "sort_order": category_data.get("sort_order", 0),
                    "is_active": category_data.get("is_active", True),
                },
            )
            category_by_slug[category.slug] = category

        for product_data in payload.get("products", []):
            category = category_by_slug.get(product_data["category_slug"])
            if category is None:
                raise ValueError(f"Categoria não encontrada: {product_data['category_slug']}")
            product = await first_or_create(
                session,
                Product,
                {"slug": product_data["slug"]},
                {
                    "category_id": category.id,
                    "name": product_data["name"],
                    "description": product_data.get("description"),
                    "product_type": product_data["product_type"],
                    "image_url": product_data.get("image_url"),
                    "sort_order": product_data.get("sort_order", 0),
                    "is_active": product_data.get("is_active", True),
                },
            )
            for size_data in product_data.get("sizes", []):
                size = await first_or_create(
                    session,
                    ProductSize,
                    {"product_id": product.id, "slug": size_data["slug"]},
                    {
                        "name": size_data["name"],
                        "price": money(size_data["price"]),
                        "slices": size_data.get("slices", 8),
                        "max_flavors": size_data.get("max_flavors", 1),
                        "is_active": size_data.get("is_active", True),
                    },
                )
                for flavor_data in size_data.get("flavors", []):
                    flavor = await first_or_create(
                        session,
                        Flavor,
                        {"name": flavor_data["name"]},
                        {
                            "description": flavor_data.get("description"),
                            "image_url": flavor_data.get("image_url"),
                            "is_active": flavor_data.get("is_active", True),
                        },
                    )
                    await first_or_create(
                        session,
                        FlavorSizePrice,
                        {"flavor_id": flavor.id, "product_size_id": size.id},
                        {"price": money(flavor_data.get("price", size_data["price"]))},
                    )

        for option_data in payload.get("edges", []):
            await first_or_create(
                session,
                Edge,
                {"name": option_data["name"]},
                {"price": money(option_data["price"]), "is_active": option_data.get("is_active", True)},
            )
        for option_data in payload.get("extras", []):
            await first_or_create(
                session,
                Extra,
                {"name": option_data["name"]},
                {"price": money(option_data["price"]), "is_active": option_data.get("is_active", True)},
            )
        await session.commit()
    print(f"Catálogo importado: {path}")


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3) or (len(sys.argv) == 3 and sys.argv[2] != "--dry-run"):
        raise SystemExit("Uso: python scripts/import_catalog.py caminho/catalogo.json [--dry-run]")
    catalog_path = Path(sys.argv[1])
    catalog_payload = json.loads(catalog_path.read_text(encoding="utf-8"))
    validate_catalog(catalog_payload)
    if len(sys.argv) == 3:
        print(f"Catálogo válido: {catalog_path}")
    else:
        asyncio.run(import_catalog(catalog_path))
