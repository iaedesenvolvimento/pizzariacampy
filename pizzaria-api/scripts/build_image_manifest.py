import argparse
import json
from pathlib import Path

from build_catalog_from_xlsx import build_catalog, read_rows


def build_manifest(source: Path, assets_dir: Path) -> dict:
    catalog, _ = build_catalog(read_rows(source))
    products = []
    for product in catalog["products"]:
        products.append(
            {
                "slug": product["slug"],
                "name": product["name"],
                "category_slug": product["category_slug"],
                "product_type": product["product_type"],
                "description": product.get("description"),
                "filename": f"{product['slug']}.jpg",
                "asset_path": str(assets_dir / f"{product['slug']}.jpg"),
                "cloudinary_public_id": f"products/{product['slug']}",
                "prompt": (
                    f"Foto gastronômica profissional de {product['name']}, "
                    f"categoria {product['category_slug'].replace('-', ' ')}, "
                    f"fundo claro, iluminação natural, composição centralizada, "
                    "sem texto, sem logotipo e formato quadrado."
                ),
            }
        )
    return {
        "source": str(source),
        "assets_dir": str(assets_dir),
        "products": products,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Gera manifesto de imagens do catálogo.")
    parser.add_argument("source", type=Path, help="Arquivo XLSX do cardápio")
    parser.add_argument("output", type=Path, help="Arquivo JSON de saída")
    parser.add_argument(
        "--assets-dir",
        type=Path,
        default=Path("assets/catalog-images"),
        help="Pasta esperada para os arquivos de imagem",
    )
    args = parser.parse_args()
    manifest = build_manifest(args.source, args.assets_dir)
    args.output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Manifesto gerado: {args.output}")
    print(f"Produtos mapeados: {len(manifest['products'])}")


if __name__ == "__main__":
    main()
