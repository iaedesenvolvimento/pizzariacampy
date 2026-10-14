import argparse
import asyncio
import json
import mimetypes
from pathlib import Path

def load_manifest(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or not isinstance(payload.get("products"), list):
        raise ValueError("Manifesto inválido: products deve ser uma lista")
    return payload


def configure_cloudinary() -> None:
    import cloudinary
    from app.core.config import settings

    cloudinary.config(
        cloud_name=settings.cloudinary_cloud_name,
        api_key=settings.cloudinary_api_key,
        api_secret=settings.cloudinary_api_secret,
        secure=True,
    )


def upload_asset(item: dict, assets_dir: Path) -> str:
    import cloudinary.uploader

    asset_path = assets_dir / item["filename"]
    if not asset_path.is_file():
        raise FileNotFoundError(asset_path)
    content_type = mimetypes.guess_type(asset_path.name)[0]
    if content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise ValueError(f"Formato não suportado: {asset_path}")
    result = cloudinary.uploader.upload(
        str(asset_path),
        public_id=item["cloudinary_public_id"],
        overwrite=True,
        invalidate=True,
        resource_type="image",
    )
    return result["secure_url"]


async def update_products(manifest: dict, uploaded: dict[str, str]) -> None:
    from sqlalchemy import select

    from app.core.database import session_factory
    from app.models.catalog import Product

    async with session_factory() as session:
        for slug, image_url in uploaded.items():
            product = await session.scalar(select(Product).where(Product.slug == slug))
            if product is None:
                raise ValueError(f"Produto não encontrado no banco: {slug}")
            product.image_url = image_url
        await session.commit()


async def run(manifest_path: Path, assets_dir: Path, dry_run: bool) -> None:
    manifest = load_manifest(manifest_path)
    missing = []
    available = []
    for item in manifest["products"]:
        asset_path = assets_dir / item["filename"]
        if asset_path.is_file():
            available.append(item)
        else:
            missing.append(item["slug"])

    print(f"Imagens encontradas: {len(available)}")
    print(f"Imagens pendentes: {len(missing)}")
    if missing:
        print("Pendentes: " + ", ".join(missing))
    if dry_run or not available:
        return

    configure_cloudinary()
    uploaded = {item["slug"]: upload_asset(item, assets_dir) for item in available}
    await update_products(manifest, uploaded)
    print(f"Produtos atualizados: {len(uploaded)}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Envia imagens e atualiza produtos.")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--assets-dir", type=Path, required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    asyncio.run(run(args.manifest, args.assets_dir, args.dry_run))


if __name__ == "__main__":
    main()
