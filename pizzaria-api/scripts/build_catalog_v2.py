"""Convert the legacy catalog export to the normalized Campy v2 format.

This command only writes a new JSON file. It does not connect to the database.
Combos are marked for review because their component distribution cannot be
reliably inferred from free-form descriptions.
"""
import argparse
import json
import re
from pathlib import Path


def slug(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-")


def build(payload: dict) -> dict:
    categories = list(payload.get("categories", []))
    if not any(item["slug"] == "doces" for item in categories):
        categories.append({"name": "Doces", "slug": "doces", "sort_order": len(categories)})

    products = payload.get("products", [])
    pizza_groups: dict[str, dict] = {}
    simple_products: list[dict] = []
    combos: list[dict] = []

    for product in products:
        category_slug = product["category_slug"]
        product_type = product.get("product_type")
        if product_type == "PIZZA":
            group = pizza_groups.setdefault(
                category_slug,
                {
                    "slug": "pizza-" + slug(category_slug),
                    "name": "Pizza salgada" if category_slug == "pizzas-salgadas" else "Pizza doce",
                    "category_slug": category_slug,
                    "product_type": "PIZZA",
                    "description": "Escolha o tamanho e o sabor da sua pizza.",
                    "sizes": [
                        {"label": "Grande", "slug": "grande", "configurations": [1, 2]},
                        {"label": "Broto", "slug": "broto", "configurations": [1]},
                    ],
                    "flavors": {},
                },
            )
            flavor_key = slug(product["name"])
            flavor = group["flavors"].setdefault(
                flavor_key,
                {
                    "slug": flavor_key,
                    "name": product["name"],
                    "description": product.get("description"),
                    "image_url": product.get("image_url"),
                    "prices": {},
                    "active": True,
                },
            )
            for size in product.get("sizes", []):
                if size.get("price") is not None:
                    flavor["prices"][size["slug"]] = size["price"]
            continue

        if product_type == "COMBO":
            combos.append(
                {
                    "slug": product["slug"],
                    "name": product["name"],
                    "category_slug": category_slug,
                    "description": product.get("description"),
                    "sizes": product.get("sizes", []),
                    "groups": [],
                    "review_required": True,
                }
            )
            continue

        normalized_type = "BEVERAGE" if category_slug == "bebidas" else "DESSERT"
        simple_products.append(
            {
                "slug": product["slug"],
                "name": product["name"],
                "category_slug": category_slug,
                "product_type": normalized_type,
                "description": product.get("description"),
                "image_url": product.get("image_url"),
                "sizes": [
                    {
                        "label": size["name"],
                        "slug": size["slug"],
                        "fixed_price": size.get("price"),
                        "active": size.get("is_active", True),
                    }
                    for size in product.get("sizes", [])
                ],
                "active": product.get("is_active", True),
            }
        )

    pizza_products = []
    for group in pizza_groups.values():
        group["flavors"] = list(group["flavors"].values())
        pizza_products.append(group)

    return {
        "schema_version": 2,
        "categories": categories,
        "pizza_products": pizza_products,
        "simple_products": simple_products,
        "combos": combos,
        "crusts": [],
        "addons": [],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    payload = json.loads(args.source.read_text(encoding="utf-8"))
    result = build(payload)
    args.destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Catálogo v2 gerado: {args.destination}")
    print(f"Pizzas: {len(result['pizza_products'])}; simples: {len(result['simple_products'])}; combos para revisão: {len(result['combos'])}")


if __name__ == "__main__":
    main()
