import pytest

from scripts.import_catalog import validate_catalog


def valid_catalog() -> dict:
    return {
        "categories": [{"name": "Pizzas", "slug": "pizzas"}],
        "products": [{
            "category_slug": "pizzas",
            "name": "Pizza Margherita",
            "slug": "pizza-margherita",
            "description": "Molho e muçarela",
            "product_type": "PIZZA",
            "sizes": [{
                "name": "Grande",
                "slug": "grande",
                "price": "49.90",
                "slices": 8,
                "max_flavors": 2,
                "flavors": [{"name": "Margherita", "price": "49.90"}],
            }],
        }],
        "edges": [{"name": "Catupiry", "price": "8.00"}],
        "extras": [{"name": "Bacon", "price": "6.00"}],
    }


def test_catalog_import_validation_accepts_real_shape() -> None:
    validate_catalog(valid_catalog())


def test_catalog_import_rejects_placeholder_values() -> None:
    payload = valid_catalog()
    payload["products"][0]["name"] = "Nome real da pizza"
    with pytest.raises(ValueError, match="texto de exemplo"):
        validate_catalog(payload)


def test_catalog_import_rejects_duplicate_slugs() -> None:
    payload = valid_catalog()
    payload["products"].append(dict(payload["products"][0]))
    with pytest.raises(ValueError, match="Slug de produto"):
        validate_catalog(payload)


def test_catalog_import_rejects_non_mvp_slice_count() -> None:
    payload = valid_catalog()
    payload["products"][0]["sizes"][0]["slices"] = 6
    with pytest.raises(ValueError, match="slices deve ser 8"):
        validate_catalog(payload)
