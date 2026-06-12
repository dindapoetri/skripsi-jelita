from pydantic import BaseModel
from typing import Optional, List, Dict


class ProductBase(BaseModel):
    id: int
    name: str
    brand: Optional[str] = None
    category: str
    description_clean: Optional[str] = None
    how_to_use: Optional[str] = None
    suitable_for: Optional[str] = None
    image_url: Optional[str] = None

    model_config = {"from_attributes": True}


class ProductWithScore(ProductBase):
    similarity_score: float


class RecommendationRequest(BaseModel):
    skin_type: str                      # normal | oily | dry | combination | sensitive
    concerns: List[str] = []            # ["jerawat", "minyak berlebih", ...]
    top_n: int = 5                      # jumlah rekomendasi per kategori


class CategoryRecommendations(BaseModel):
    facial_wash: List[ProductWithScore] = []
    toner: List[ProductWithScore] = []
    moisturizer: List[ProductWithScore] = []
    sunscreen: List[ProductWithScore] = []


class RecommendationResponse(BaseModel):
    skin_type: str
    concerns: List[str]
    recommendations: CategoryRecommendations
    total_products_analyzed: int
