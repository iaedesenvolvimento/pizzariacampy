import os
from uuid import uuid4

os.environ["DATABASE_URL"] = "postgresql+asyncpg://test:test@localhost/test"
os.environ["SECRET_KEY"] = "test-secret-key-with-at-least-32-bytes-long"
os.environ["DEBUG"] = "false"

import jwt
import pytest
import logging

from app.core.security import create_access_token, decode_access_token, hash_password, verify_password
from app.services.coupons import CouponError, compute_discount
from app.services.orders import ORDER_TRANSITIONS, OrderError
from app.core.observability import JsonFormatter
from app.core.rate_limit import InMemoryRateLimiter


def test_password_hash_round_trip() -> None:
    password_hash = hash_password("SenhaSegura123!")
    assert verify_password("SenhaSegura123!", password_hash)
    assert not verify_password("senha-incorreta", password_hash)


def test_access_token_contains_user_and_role() -> None:
    user_id = uuid4()
    payload = decode_access_token(create_access_token(user_id, "CUSTOMER"))
    assert payload["sub"] == str(user_id)
    assert payload["role"] == "CUSTOMER"


def test_invalid_access_token_is_rejected() -> None:
    with pytest.raises(jwt.InvalidTokenError):
        decode_access_token("invalid.token.value")


def test_coupon_fixed_discount_is_capped_at_subtotal() -> None:
    assert compute_discount("FIXED", 25, 10) == 10


def test_coupon_percentage_discount() -> None:
    assert compute_discount("PERCENTAGE", 10, 75) == 7.50


def test_coupon_percentage_above_100_is_rejected() -> None:
    with pytest.raises(CouponError, match="exceed"):
        compute_discount("PERCENTAGE", 101, 75)


def test_order_state_machine_does_not_allow_regression() -> None:
    assert "PREPARING" not in ORDER_TRANSITIONS["DELIVERED"]
    assert "PREPARING" in ORDER_TRANSITIONS["CONFIRMED"]


def test_invalid_order_transition_has_domain_error() -> None:
    assert OrderError("INVALID_ORDER_TRANSITION", "invalid").code == "INVALID_ORDER_TRANSITION"


def test_rate_limiter_blocks_after_limit() -> None:
    limiter = InMemoryRateLimiter(limit=2, window_seconds=60)
    assert limiter.allow("client")[0]
    assert limiter.allow("client")[0]
    assert not limiter.allow("client")[0]


def test_json_log_does_not_include_sensitive_payload() -> None:
    record = logging.LogRecord("test", logging.INFO, "", 0, "request completed", (), None)
    record.request_id = "request-1"
    record.method = "POST"
    record.path = "/api/v1/auth/login"
    formatted = JsonFormatter().format(record)
    assert "request-1" in formatted
    assert "password" not in formatted.lower()
    assert "token" not in formatted.lower()
