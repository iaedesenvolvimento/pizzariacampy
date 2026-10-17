"""Idempotently import the normalized Campy v2 catalog.

The command intentionally does not publish combos marked ``review_required``.
Their free-form source description must be confirmed by the owner first.
"""
import argparse
import asyncio
import json
from decimal import Decimal
from pathlib import Path
from uuid import uuid4

from sqlalchemy import text


def money(value):
    if value is None:
        return None
    return Decimal(str(value)).quantize(Decimal("0.01"))


def validate_payload(payload: dict) -> None:
    if payload.get("schema_version") != 2:
        raise ValueError("O arquivo precisa usar schema_version 2")
    categories = {item["slug"] for item in payload.get("categories", [])}
    if len(categories) != len(payload.get("categories", [])):
        raise ValueError("Há categorias duplicadas")
    for collection in ("pizza_products", "simple_products", "combos"):
        for item in payload.get(collection, []):
            if item.get("category_slug") not in categories:
                raise ValueError(f"Categoria inexistente em {collection}: {item.get('category_slug')}")
    for item in payload.get("pizza_products", []):
        if item.get("product_type") != "PIZZA":
            raise ValueError(f"Produto de pizza com tipo inválido: {item.get('slug')}")
        for size in item.get("sizes", []):
            configurations = size.get("configurations", [])
            if any(count not in (1, 2) for count in configurations):
                raise ValueError(f"Configuração de pizza inválida em {item.get('slug')}")
        for flavor in item.get("flavors", []):
            for price in flavor.get("prices", {}).values():
                if price is not None and money(price) < 0:
                    raise ValueError(f"Preço negativo no sabor {flavor.get('name')}")


async def one(session, query: str, params: dict):
    return await session.scalar(text(query), params)


async def ensure_category(session, item: dict):
    category_id = await one(session, "SELECT id FROM categories WHERE slug = :slug", {"slug": item["slug"]})
    if category_id is None:
        category_id = uuid4()
        await session.execute(text("""
            INSERT INTO categories (id, name, slug, sort_order, is_active)
            VALUES (:id, :name, :slug, :sort_order, :active)
        """), {"id": category_id, "name": item["name"], "slug": item["slug"], "sort_order": item.get("sort_order", 0), "active": item.get("is_active", True)})
    return category_id


async def ensure_product(session, item: dict, category_id):
    product_id = await one(session, "SELECT id FROM products WHERE slug = :slug", {"slug": item["slug"]})
    values = {"category_id": category_id, "name": item["name"], "description": item.get("description"), "product_type": item["product_type"], "image_url": item.get("image_url"), "active": item.get("active", True), "slug": item["slug"]}
    if product_id is None:
        product_id = uuid4()
        await session.execute(text("""
            INSERT INTO products (id, category_id, name, slug, description, product_type, image_url, is_active)
            VALUES (:id, :category_id, :name, :slug, :description, :product_type, :image_url, :active)
        """), {"id": product_id, **values})
    else:
        await session.execute(text("""
            UPDATE products SET category_id=:category_id, name=:name, description=:description,
                product_type=:product_type, image_url=:image_url, is_active=:active, version=version+1
            WHERE id=:id
        """), {"id": product_id, **values})
    return product_id


async def ensure_size(session, product_id, item: dict, pizza: bool):
    size_id = await one(session, "SELECT id FROM product_sizes WHERE product_id=:product_id AND slug=:slug", {"product_id": product_id, "slug": item["slug"]})
    fixed_price = money(item.get("fixed_price", item.get("price")))
    if size_id is None:
        size_id = uuid4()
        await session.execute(text("""
            INSERT INTO product_sizes (id, product_id, name, slug, price, fixed_price, slices, max_flavors, is_active)
            VALUES (:id, :product_id, :name, :slug, :price, :fixed_price, 8, :max_flavors, true)
        """), {"id": size_id, "product_id": product_id, "name": item["label"], "slug": item["slug"], "price": fixed_price, "fixed_price": fixed_price, "max_flavors": 2 if pizza else 1})
    else:
        await session.execute(text("""
            UPDATE product_sizes SET name=:name, price=COALESCE(:price, price), fixed_price=:fixed_price,
                max_flavors=:max_flavors, is_active=true WHERE id=:id
        """), {"id": size_id, "name": item["label"], "price": fixed_price, "fixed_price": fixed_price, "max_flavors": 2 if pizza else 1})
    return size_id


async def seed(path: Path, dry_run: bool) -> None:
    payload = json.loads(path.read_text(encoding="utf-8"))
    validate_payload(payload)
    if dry_run:
        pending_combos = sum(1 for item in payload.get("combos", []) if item.get("review_required"))
        print(f"Catálogo v2 válido: {path}; combos pendentes de revisão: {pending_combos}")
        return
    from app.core.database import session_factory

    async with session_factory() as session:
        categories = {item["slug"]: await ensure_category(session, item) for item in payload.get("categories", [])}
        for item in payload.get("pizza_products", []):
            product_id = await ensure_product(session, item, categories[item["category_slug"]])
            sizes = {size["slug"]: await ensure_size(session, product_id, size, True) for size in item.get("sizes", [])}
            for flavor_item in item.get("flavors", []):
                flavor_id = await one(session, "SELECT id FROM flavors WHERE name=:name", {"name": flavor_item["name"]})
                if flavor_id is None:
                    flavor_id = uuid4()
                    await session.execute(text("""
                        INSERT INTO flavors (id, name, description, image_url, is_active, version)
                        VALUES (:id, :name, :description, :image_url, :active, 1)
                    """), {"id": flavor_id, "name": flavor_item["name"], "description": flavor_item.get("description"), "image_url": flavor_item.get("image_url"), "active": flavor_item.get("active", True)})
                await session.execute(text("""
                    INSERT INTO product_flavors (product_id, flavor_id) VALUES (:product_id, :flavor_id)
                    ON CONFLICT DO NOTHING
                """), {"product_id": product_id, "flavor_id": flavor_id})
                for size_slug, price in flavor_item.get("prices", {}).items():
                    if size_slug not in sizes or price is None:
                        continue
                    await session.execute(text("""
                        INSERT INTO flavor_size_prices (id, product_id, flavor_id, product_size_id, price)
                        VALUES (:id, :product_id, :flavor_id, :product_size_id, :price)
                        ON CONFLICT (flavor_id, product_size_id) DO UPDATE SET product_id=EXCLUDED.product_id, price=EXCLUDED.price
                    """), {"id": uuid4(), "product_id": product_id, "flavor_id": flavor_id, "product_size_id": sizes[size_slug], "price": money(price)})
            for size in item.get("sizes", []):
                for count in size.get("configurations", []):
                    await session.execute(text("""
                        INSERT INTO pizza_configurations (id, product_size_id, flavor_count, display_name, display_order, pricing_rule, is_active)
                        VALUES (:id, :size_id, :count, :name, :display_order, 'MAX_FLAVOR_PRICE', true)
                        ON CONFLICT (product_size_id, flavor_count) DO UPDATE SET display_name=EXCLUDED.display_name, is_active=true
                    """), {"id": uuid4(), "size_id": sizes[size["slug"]], "count": count, "name": f"{size['label']} — {count} sabor{'es' if count != 1 else ''}", "display_order": count})

        for item in payload.get("simple_products", []):
            product_id = await ensure_product(session, item, categories[item["category_slug"]])
            for size in item.get("sizes", []):
                await ensure_size(session, product_id, size, False)

        await session.commit()
    print(f"Seed v2 executado: {path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("catalog", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    asyncio.run(seed(args.catalog, args.dry_run))
