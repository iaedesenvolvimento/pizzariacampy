import asyncio
from decimal import Decimal
from uuid import uuid4

import pytest

from app.services.pricing import PricingError, get_flavor_prices


class _Result:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows


class _Session:
    def __init__(self, rows):
        self.rows = rows

    async def execute(self, _statement):
        return _Result(self.rows)


def test_missing_prices_for_unconfigured_size_use_base_price() -> None:
    flavor_id = uuid4()
    prices = asyncio.run(
        get_flavor_prices(
            _Session([]), uuid4(), [flavor_id], fallback_price=Decimal("4.00")
        )
    )

    assert prices == {flavor_id: Decimal("4.00")}


def test_partial_flavor_prices_remain_invalid() -> None:
    flavor_id = uuid4()

    with pytest.raises(PricingError, match="unavailable"):
        asyncio.run(
            get_flavor_prices(
                _Session([(flavor_id, Decimal("4.00"))]),
                uuid4(),
                [flavor_id, uuid4()],
                fallback_price=Decimal("4.00"),
            )
        )
