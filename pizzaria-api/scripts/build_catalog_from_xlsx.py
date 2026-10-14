import json
import re
import sys
import unicodedata
import zipfile
import xml.etree.ElementTree as ET
from collections import OrderedDict
from decimal import Decimal
from pathlib import Path


NAMESPACE = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
CATEGORY_TYPES = {
    "Pizzas salgadas": "PIZZA",
    "Pizzas doces": "PIZZA",
    "Bebidas": "BEVERAGE",
    "Esfihas salgadas": "DESSERT",
    "Esfihas doces": "DESSERT",
    "Combos de esfihas": "COMBO",
}


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii").lower()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_value).strip("-")
    return slug or "item"


def product_name(value: str) -> str:
    return re.sub(r"^\d+\.\s*", "", value).strip()


def read_rows(path: Path) -> list[dict[str, str]]:
    with zipfile.ZipFile(path) as workbook:
        root = ET.fromstring(workbook.read("xl/worksheets/sheet1.xml"))
    rows = root.findall(".//m:sheetData/m:row", NAMESPACE)
    values = []
    for row in rows:
        row_values = {}
        for cell in row.findall("m:c", NAMESPACE):
            match = re.match(r"[A-Z]+", cell.attrib["r"])
            if not match:
                continue
            value = cell.find("m:v", NAMESPACE)
            row_values[match.group()] = "" if value is None else (value.text or "")
        values.append(row_values)
    headers = values[0]
    return [{headers[column]: value for column, value in row.items()} for row in values[1:]]


def build_catalog(rows: list[dict[str, str]]) -> tuple[dict, list[dict[str, str]]]:
    categories = OrderedDict()
    products = OrderedDict()
    skipped = []

    for row_number, row in enumerate(rows, start=2):
        category_name = row["categoria"].strip()
        raw_name = row["produto"].strip()
        name = product_name(raw_name)
        price = row["preço"].strip()
        category_slug = slugify(category_name)
        product_slug = slugify(name)

        categories.setdefault(category_slug, {
            "name": category_name,
            "slug": category_slug,
            "sort_order": len(categories),
        })
        key = (category_slug, product_slug)
        product = products.setdefault(key, {
            "name": name,
            "slug": product_slug,
            "category_slug": category_slug,
            "product_type": CATEGORY_TYPES[category_name],
            "description": row["descrição"].strip() or None,
            "sort_order": len(products),
            "sizes": [],
        })

        if not price:
            skipped.append({
                "row": str(row_number),
                "category": category_name,
                "product": name,
                "size": row["tamanho"].strip(),
                "reason": "preço não informado",
            })
            continue

        size_name = row["tamanho"].strip()
        size_slug = slugify(size_name)
        flavor_name = row["sabores"].strip()
        size = {
            "name": size_name,
            "slug": size_slug,
            "price": str(Decimal(price).quantize(Decimal("0.01"))),
            "slices": 8,
            "max_flavors": 1,
        }
        if CATEGORY_TYPES[category_name] == "PIZZA" and flavor_name:
            size["flavors"] = [{"name": flavor_name, "price": size["price"]}]
        product["sizes"].append(size)

    valid_products = []
    for product in products.values():
        if product["sizes"]:
            valid_products.append(product)
        else:
            skipped.append({
                "row": "",
                "category": next(c["name"] for c in categories.values() if c["slug"] == product["category_slug"]),
                "product": product["name"],
                "size": "",
                "reason": "produto sem nenhum tamanho com preço",
            })

    slug_counts = {}
    for product in valid_products:
        slug_counts[product["slug"]] = slug_counts.get(product["slug"], 0) + 1
    for product in valid_products:
        if slug_counts[product["slug"]] > 1:
            product["slug"] = f"{product['slug']}-{product['category_slug']}"

    payload = {
        "categories": list(categories.values()),
        "products": valid_products,
        "edges": [],
        "extras": [],
    }
    return payload, skipped


def main() -> None:
    if len(sys.argv) not in (2, 3):
        raise SystemExit("Uso: python scripts/build_catalog_from_xlsx.py cardapio.xlsx [saida.json]")
    source = Path(sys.argv[1])
    output = Path(sys.argv[2]) if len(sys.argv) == 3 else Path("catalogo-real.json")
    payload, skipped = build_catalog(read_rows(source))
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report = output.with_name(output.stem + ".skipped.json")
    report.write_text(json.dumps(skipped, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Catálogo gerado: {output}")
    print(f"Categorias: {len(payload['categories'])}; produtos: {len(payload['products'])}; linhas ignoradas: {len(skipped)}")
    print(f"Relatório de revisão: {report}")


if __name__ == "__main__":
    main()
