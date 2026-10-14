from datetime import time

from pydantic import BaseModel, Field


class BusinessHoursRequest(BaseModel):
    open_time: time | None = None
    close_time: time | None = None
    is_closed: bool = False


class BusinessHoursResponse(BusinessHoursRequest):
    weekday: int = Field(ge=0, le=6)


class BusinessStatusResponse(BaseModel):
    status: str
    message: str
    next_open_at: str | None = None
    server_time: str
