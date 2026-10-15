from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CoverageLocationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    city: str
    neighborhood: str
    aliases: str | None
    source: str
    is_active: bool


class CoverageLocationUpdate(BaseModel):
    is_active: bool
