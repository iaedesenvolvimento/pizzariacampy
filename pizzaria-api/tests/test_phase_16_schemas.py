import pytest
from pydantic import ValidationError

from app.schemas.addresses import AddressCreate
from app.schemas.payments import PaymentReviewRequest


def test_address_requires_delivery_fields() -> None:
    address = AddressCreate(
        label="Casa",
        address="Rua Bela, 49",
        neighborhood="Centro",
        city="Carapicuíba",
        is_default=True,
    )
    assert address.is_default


def test_address_rejects_empty_label() -> None:
    with pytest.raises(ValidationError):
        AddressCreate(label="", address="Rua", neighborhood="Centro", city="Carapicuíba")


def test_payment_review_only_accepts_final_statuses() -> None:
    assert PaymentReviewRequest(status="CONFIRMED").status == "CONFIRMED"
    with pytest.raises(ValidationError):
        PaymentReviewRequest(status="PENDING")
