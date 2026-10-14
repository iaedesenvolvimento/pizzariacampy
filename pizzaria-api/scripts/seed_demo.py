import asyncio
from decimal import Decimal

from sqlalchemy import select

from app.core.database import session_factory
from app.models.catalog import Category, Edge, Extra, Flavor, FlavorSizePrice, Product, ProductSize


async def first_or_create(session, model, lookup: dict, values: dict):
    item = await session.scalar(select(model).filter_by(**lookup))
    if item is None:
        item = model(**lookup, **values)
        session.add(item)
        await session.flush()
    return item


async def seed() -> None:
    async with session_factory() as session:
        pizzas = await first_or_create(
            session,
            Category,
            {"slug": "pizzas"},
            {"name": "Pizzas", "description": "Pizzas artesanais da Campy", "sort_order": 1},
        )
        drinks = await first_or_create(
            session,
            Category,
            {"slug": "bebidas"},
            {"name": "Bebidas", "description": "Bebidas geladas", "sort_order": 2},
        )

        pizza_products = [
            ("Pizza Calabresa", "pizza-calabresa", "Molho, muçarela e calabresa", 1),
            ("Pizza Margherita", "pizza-margherita", "Molho, muçarela, tomate e manjericão", 2),
        ]
        sizes = []
        for name, slug, description, sort_order in pizza_products:
            product = await first_or_create(
                session,
                Product,
                {"slug": slug},
                {"category_id": pizzas.id, "name": name, "description": description, "product_type": "PIZZA", "sort_order": sort_order},
            )
            size = await first_or_create(
                session,
                ProductSize,
                {"product_id": product.id, "slug": "grande"},
                {"name": "Grande", "price": Decimal("49.90"), "slices": 8, "max_flavors": 2},
            )
            sizes.append(size)

        flavors = []
        for name in ["Calabresa", "Margherita", "Frango com Catupiry"]:
            flavor = await first_or_create(session, Flavor, {"name": name}, {"description": f"Sabor {name}"})
            flavors.append(flavor)
        for size in sizes:
            for flavor in flavors:
                await first_or_create(session, FlavorSizePrice, {"flavor_id": flavor.id, "product_size_id": size.id}, {"price": Decimal("49.90")})

        drink = await first_or_create(
            session,
            Product,
            {"slug": "coca-cola-lata"},
            {
                "category_id": drinks.id,
                "name": "Coca-Cola Lata",
                "description": "Lata 350 ml",
                "product_type": "DRINK",
                "sort_order": 1,
            },
        )
        await first_or_create(
            session,
            ProductSize,
            {"product_id": drink.id, "slug": "lata"},
            {"name": "Lata", "price": Decimal("6.00"), "slices": 1, "max_flavors": 1},
        )
        await first_or_create(session, Edge, {"name": "Borda Catupiry"}, {"price": Decimal("8.00")})
        await first_or_create(session, Edge, {"name": "Borda Cheddar"}, {"price": Decimal("8.00")})
        await first_or_create(session, Extra, {"name": "Bacon"}, {"price": Decimal("6.00")})
        await first_or_create(session, Extra, {"name": "Azeitona"}, {"price": Decimal("3.00")})
        await session.commit()
    print("Demo catalog seeded successfully.")


if __name__ == "__main__":
    asyncio.run(seed())
