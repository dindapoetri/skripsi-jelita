from pydantic import BaseModel, field_validator
from typing import Optional, List, Dict
from datetime import datetime
from uuid import UUID


class HistoryScanResponse(BaseModel):
    id:                 UUID
    user_id:            Optional[UUID] = None
    device_id:          Optional[str] = None
    face_capture_id:    Optional[UUID] = None
    image_url:          Optional[str] = None
    skin_type:          str
    skin_condition_id:  Optional[UUID] = None
    confidence_score:   Optional[float] = None
    detected_symptoms:  Optional[List[str]] = None
    concerns:           Optional[List[str]]  = None         
    description:        Optional[str]        = None       
    probabilities:      Optional[Dict[str, float]] = None    
    recommendations:    Optional[List[str]]  = None        
    ideal_ingredients:  Optional[List[str]]  = None           
    created_at:         Optional[datetime] = None

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
    history_id: Optional[str] = None