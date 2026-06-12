from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.db.database import get_db
from app.schemas.product_schema import RecommendationRequest, RecommendationResponse
from app.services.cbf_service import get_recommendations
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


@router.post(
    "/",
    response_model=RecommendationResponse,
    summary="Dapatkan rekomendasi produk berdasarkan jenis kulit (CBF)",
)
async def recommend(
    data: RecommendationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Endpoint utama rekomendasi CBF.

    - **skin_type**: hasil klasifikasi CNN (normal/oily/dry/combination/sensitive)
    - **concerns**: keluhan kulit pengguna (jerawat, minyak berlebih, dll)
    - **top_n**: jumlah produk per kategori (default 5)
    """
    recs = await get_recommendations(
        skin_type=data.skin_type,
        concerns=data.concerns,
        top_n=data.top_n,
        db=db,
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


@router.post(
    "/guest",
    response_model=RecommendationResponse,
    summary="Rekomendasi tanpa login (untuk testing)",
)
async def recommend_guest(
    data: RecommendationRequest,
    db: AsyncSession = Depends(get_db),
):
    """Sama seperti /recommendations/ tapi tanpa autentikasi. Untuk dev/testing."""
    recs = await get_recommendations(
        skin_type=data.skin_type,
        concerns=data.concerns,
        top_n=data.top_n,
        db=db,
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
