from collections.abc import Sequence
from typing import Protocol


class PaymentProcessor(Protocol):
    supported_methods: Sequence[str]

    def supports(self, method: str) -> bool:
        ...


class ManualPaymentProcessor:
    supported_methods = ("PIX", "CASH", "CARD_ON_DELIVERY")

    def supports(self, method: str) -> bool:
        return method in self.supported_methods


payment_processor = ManualPaymentProcessor()
