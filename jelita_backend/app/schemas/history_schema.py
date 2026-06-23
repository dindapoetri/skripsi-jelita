from pydantic import BaseModel, field_validator
from typing import Optional, List, Any
from datetime import datetime


class HistoryScanResponse(BaseModel):
    id:                       int
    user_id:                  int
    skin_type:                str
    cnn_confidence:           Optional[float] = None
    concerns:                 Optional[List[str]] = None
    image_url:                Optional[str] = None
    recommendations_snapshot: Optional[List[Any]] = None
    created_at:               datetime

    model_config = {"from_attributes": True}

    @field_validator("created_at", mode="before")
    @classmethod
    def parse_datetime(cls, v):
        if isinstance(v, str):
            return datetime.fromisoformat(v.replace("Z", "+00:00"))
        return v


class CNNPredictResponse(BaseModel):
    skin_type:  str
    confidence: float
    all_scores: dict
    image_url:  Optional[str] = None
    history_id: Optional[int] = None