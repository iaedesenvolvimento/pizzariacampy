import argparse
import json
import os
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


API_URL = "https://cloud.leonardo.ai/api/rest/v1"
DEFAULT_MODEL_ID = "7b592283-e8a7-4c5a-9ba6-d18c31f258b9"


def request_json(method: str, url: str, api_key: str, payload: dict | None = None) -> dict:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    request = Request(
        url,
        data=body,
        method=method,
        headers={
            "accept": "application/json",
            "authorization": f"Bearer {api_key}",
            "content-type": "application/json",
        },
    )
    try:
        with urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError) as error:
        detail = error.read().decode("utf-8", errors="replace") if isinstance(error, HTTPError) else str(error)
        raise RuntimeError(f"Leonardo API falhou: {detail}") from error


def generation_id(response: dict) -> str:
    job = response.get("sdGenerationJob") or {}
    value = response.get("generationId") or job.get("generationId")
    if not value:
        raise RuntimeError(f"Resposta sem generationId: {response}")
    return str(value)


def generated_url(response: dict) -> str | None:
    data = response.get("generations_by_pk") or response.get("generation") or response
    images = data.get("generated_images") or data.get("images") or []
    if not images:
        return None
    image = images[0]
    return image.get("url") or image.get("uri")


def download(url: str, destination: Path, api_key: str) -> None:
    headers = {
        "accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        "user-agent": "pizzaria-campy-image-importer/1.0",
    }
    try:
        with urlopen(Request(url, headers=headers), timeout=120) as response:
            destination.write_bytes(response.read())
    except HTTPError as error:
        if error.code != 403:
            raise
        headers["authorization"] = f"Bearer {api_key}"
        try:
            with urlopen(Request(url, headers=headers), timeout=120) as response:
                destination.write_bytes(response.read())
        except HTTPError as retry_error:
            detail = retry_error.read().decode("utf-8", errors="replace")
            raise RuntimeError(
                f"Leonardo bloqueou o download da imagem ({retry_error.code}). "
                "Verifique o acesso da API e tente novamente. "
                f"Resposta: {detail[:300]}"
            ) from retry_error


def generate_item(item: dict, api_key: str, output_dir: Path, model_id: str, wait_seconds: int) -> Path:
    response = request_json(
        "POST",
        f"{API_URL}/generations",
        api_key,
        {
            "alchemy": False,
            "height": 768,
            "modelId": model_id,
            "num_images": 1,
            "prompt": item["prompt"],
            "width": 768,
        },
    )
    job_id = generation_id(response)
    deadline = time.monotonic() + wait_seconds
    image_url = None
    while time.monotonic() < deadline:
        image_url = generated_url(request_json("GET", f"{API_URL}/generations/{job_id}", api_key))
        if image_url:
            break
        time.sleep(5)
    if not image_url:
        raise TimeoutError(f"Geração não concluída no prazo: {item['slug']}")
    destination = output_dir / item["filename"]
    download(image_url, destination, api_key)
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description="Gera imagens do catálogo pelo Leonardo AI.")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--limit", type=int, default=3)
    parser.add_argument("--category-slug", action="append", default=[])
    parser.add_argument("--wait-seconds", type=int, default=180)
    parser.add_argument("--model-id", default=os.getenv("LEONARDO_MODEL_ID", DEFAULT_MODEL_ID))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    items = manifest.get("products", [])
    if args.category_slug:
        items = [item for item in items if item.get("category_slug") in args.category_slug]
    items = items[: args.limit]
    print(f"Produtos selecionados: {len(items)}")
    for item in items:
        print(f"- {item['slug']}: {item['prompt']}")
    if args.dry_run:
        return
    api_key = os.getenv("LEONARDO_API_KEY")
    if not api_key:
        raise SystemExit("Defina LEONARDO_API_KEY antes de gerar imagens.")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for item in items:
        destination = args.output_dir / item["filename"]
        if destination.exists():
            print(f"Ignorado, já existe: {destination.name}")
            continue
        print(f"Gerando: {item['slug']}")
        print(f"Salvo em: {generate_item(item, api_key, args.output_dir, args.model_id, args.wait_seconds)}")


if __name__ == "__main__":
    main()
