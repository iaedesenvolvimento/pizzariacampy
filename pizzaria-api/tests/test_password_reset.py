import pytest
from pydantic import ValidationError

from app.schemas.auth import PasswordRecoveryRequest, PasswordResetRequest


def test_password_recovery_normalizes_email_type() -> None:
    request = PasswordRecoveryRequest(email="cliente@example.com")
    assert str(request.email) == "cliente@example.com"


def test_password_reset_rejects_weak_password() -> None:
    with pytest.raises(ValidationError):
        PasswordResetRequest(token="a" * 24, password="senha-fraca")


def test_password_reset_accepts_strong_password() -> None:
    request = PasswordResetRequest(token="a" * 24, password="SenhaForte123")
    assert request.password == "SenhaForte123"
