import asyncio
import os
from datetime import date
from decimal import Decimal

import pytest

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost/test")
os.environ.setdefault("SECRET_KEY", "test-secret-key-with-at-least-32-bytes-long")

from app.services.finance import SALES_DEFINITION, get_summary, resolve_period


class _Result:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows


class _SummarySession:
    def __init__(self, values, rows):
        self._values = iter(values)
        self._rows = rows

    async def scalar(self, _statement):
        return next(self._values)

    async def execute(self, _statement):
        return _Result(self._rows)


def test_finance_period_uses_sao_paulo_and_semi_open_utc_interval() -> None:
    start_date, end_date, start_utc, end_utc = resolve_period(
        date(2026, 10, 16), date(2026, 10, 16)
    )

    assert start_date == date(2026, 10, 16)
    assert end_date == date(2026, 10, 16)
    assert start_utc.isoformat() == "2026-10-16T03:00:00+00:00"
    assert end_utc.isoformat() == "2026-10-17T03:00:00+00:00"


def test_finance_period_requires_complete_date_pair() -> None:
    with pytest.raises(ValueError, match="informados juntos"):
        resolve_period(date(2026, 10, 16), None)

    with pytest.raises(ValueError, match="maior ou igual"):
        resolve_period(date(2026, 10, 17), date(2026, 10, 16))


def test_finance_definition_does_not_claim_received_amount() -> None:
    assert "faturamento operacional" in SALES_DEFINITION
    assert "recebimento confirmado" in SALES_DEFINITION
    assert Decimal("3.50") + Decimal("0.01") == Decimal("3.51")


def test_finance_summary_aggregates_operational_sales() -> None:
    session = _SummarySession(
        values=[2, Decimal("110.10"), Decimal("10.10"), Decimal("7.00"), 1, Decimal("20.00"), 1, 1],
        rows=[("CASH", 1, Decimal("50.00")), ("PIX", 1, Decimal("60.10"))],
    )

    summary = asyncio.run(get_summary(session, date(2026, 10, 16), date(2026, 10, 16)))

    assert summary.gross_sales == Decimal("110.10")
    assert summary.orders_count == 2
    assert summary.average_ticket == Decimal("55.05")
    assert summary.discounts_total == Decimal("10.10")
    assert summary.delivery_fees_total == Decimal("7.00")
    assert summary.cancelled_orders_count == 1
    assert summary.cancelled_amount == Decimal("20.00")
    assert summary.pix_pending_count == 2
    assert [item.method for item in summary.payment_methods] == ["CASH", "PIX"]


def test_finance_summary_returns_zero_for_empty_period() -> None:
    session = _SummarySession(values=[0, None, None, None, 0, None, 0, 0], rows=[])

    summary = asyncio.run(get_summary(session, date(2026, 10, 16), date(2026, 10, 16)))

    assert summary.gross_sales == Decimal("0.00")
    assert summary.average_ticket == Decimal("0.00")
    assert summary.payment_methods == []
