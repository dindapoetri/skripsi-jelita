from fastapi import APIRouter, Depends
from app.schemas.product_schema import RecommendationRequest, RecommendationResponse
from app.services.cbf_service import get_recommendations
from app.core.security import get_current_user
from app.db.database import supabase_admin

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


async def _handle(data: RecommendationRequest):
    recs = await get_recommendations(
        skin_type=data.skin_type,
        concerns=data.concerns,
        top_n=data.top_n,
    )

    total = sum([
        len(recs.facial_wash),
        len(recs.toner),
        len(recs.moisturizer),
        len(recs.sunscreen),
    ])

    return RecommendationResponse(
        skin_type=data.skin_type,
        concerns=data.concerns,
        recommendations=recs,
        total_products_analyzed=total,
    )


@router.post("/", response_model=RecommendationResponse)
async def recommend(
    data: RecommendationRequest,
    current_user: dict = Depends(get_current_user),
):
    return await _handle(data)


@router.post("/guest", response_model=RecommendationResponse)
async def recommend_guest(data: RecommendationRequest):
    return await _handle(data)

    
@router.get("/db-test")
def db_test():
    result = (
        supabase_admin
        .table("products")
        .select("id")
        .limit(1)
        .execute()
    )

    return {
        "success": True,
        "rows": len(result.data)
    }