from __future__ import annotations

from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, Field


PLCState = Literal["NOMINAL", "ALTERED", "UNKNOWN"]
LampState = Literal["GREEN", "RED", "OFF"]


class ParameterStatus(BaseModel):
    register: int
    name: str
    value: int
    nominal: int
    range: Optional[List[int]] = None
    valid_values: Optional[List[int]] = None
    in_range: bool


class PLCStatus(BaseModel):
    id: int
    name: str
    host: str
    port: int
    state: PLCState
    lamp: LampState
    attacked: bool
    last_read: Optional[datetime] = None
    parameters: List[ParameterStatus] = Field(default_factory=list)


class PlantStatus(BaseModel):
    plant: str
    timestamp: datetime
    plcs: List[PLCStatus]
