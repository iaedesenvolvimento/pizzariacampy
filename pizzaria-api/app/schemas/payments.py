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
