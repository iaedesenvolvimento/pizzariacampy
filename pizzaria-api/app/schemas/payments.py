from pydantic import BaseModel, Field, HttpUrl


class PaymentMethodResponse(BaseModel):
    method: str
    title: str
    description: str
    requires_proof: bool
    collects_card_data: bool


class PaymentProofRequest(BaseModel):
    proof_url: HttpUrl


class PaymentReviewRequest(BaseModel):
    status: str = Field(pattern=r"^(CONFIRMED|FAILED)$")
    notes: str | None = Field(default=None, max_length=300)


class MercadoPagoPixResponse(BaseModel):
    payment_id: str
    status: str
    qr_code: str | None = None
    qr_code_base64: str | None = None
    ticket_url: str | None = None
