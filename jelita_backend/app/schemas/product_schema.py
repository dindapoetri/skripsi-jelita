from pydantic import BaseModel
from typing import Optional, List
import uuid


class ProductBase(BaseModel):
    id: uuid.UUID                        # ← UUID bukan int
    name: str
    brand: Optional[str] = None
    category: Optional[str] = None
    description_clean: Optional[str] = None
    suitable_for: Optional[str] = None
    image_url: Optional[str] = None
    skin_types: Optional[List[str]] = []
    concerns: Optional[List[str]] = []

    model_config = {"from_attributes": True}


class ProductWithScore(ProductBase):
    similarity_score: float = 0.0


class RecommendationRequest(BaseModel):
    skin_type: str
    concerns:  List[str] = []
    top_n:     int = 5


class CategoryRecommendations(BaseModel):
    facial_wash:  List[ProductWithScore] = []
    toner:        List[ProductWithScore] = []
    moisturizer:  List[ProductWithScore] = []
    sunscreen:    List[ProductWithScore] = []


class RecommendationResponse(BaseModel):
    skin_type:                str
    concerns:                 List[str]
    recommendations:          CategoryRecommendations
    total_products_analyzed:  int