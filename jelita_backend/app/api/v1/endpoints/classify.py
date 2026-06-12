from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
import json

from app.db.database import get_db
from app.schemas.history_schema import CNNPredictResponse, HistoryScanCreate
from app.services.cnn_service import predict_skin_type
from app.services.cbf_service import get_recommendations
from app.services.history_service import create_history_scan
from app.utils.file_utils import save_upload_photo
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter(prefix="/classify", tags=["CNN Classification"])


@router.post(
    "/",
    response_model=CNNPredictResponse,
    summary="Upload foto wajah → klasifikasi CNN → simpan ke riwayat",
)
async def classify_and_save(
    photo: UploadFile = File(..., description="Foto wajah pengguna (JPG/PNG)"),
    concerns: str = Form(default="[]", description='JSON array: ["jerawat","minyak berlebih"]'),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Alur lengkap:
    1. Upload & simpan foto ke disk
    2. Jalankan CNN inference → dapat skin_type + confidence
    3. Jalankan CBF → dapat rekomendasi produk
    4. Simpan hasil ke tabel history_scans
    5. Return hasil ke Flutter
    """

    # 1. Simpan foto
    image_path, image_bytes = await save_upload_photo(photo, subfolder="scans")

    # 2. CNN inference
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)

    # 3. Parse concerns dari form
    try:
        concerns_list: List[str] = json.loads(concerns)
        if not isinstance(concerns_list, list):
            concerns_list = []
    except (json.JSONDecodeError, ValueError):
        concerns_list = []

    # 4. Ambil rekomendasi CBF (untuk disimpan sebagai snapshot)
    recs = await get_recommendations(
        skin_type=skin_type,
        concerns=concerns_list,
        top_n=5,
        db=db,
    )

    # Flatten rekomendasi untuk snapshot
    snapshot = []
    for cat_name, products in recs.model_dump().items():
        for p in products:
            p["category"] = cat_name
            snapshot.append(p)

    # 5. Simpan ke history_scans
    history = await create_history_scan(
        db=db,
        user_id=current_user.id,
        data=HistoryScanCreate(
            skin_type=skin_type,
            cnn_confidence=confidence,
            concerns=concerns_list,
            image_url=image_path,
            recommendations_snapshot=snapshot,
        ),
    )

    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
        image_url=image_path,
        history_id=history.id,
    )


@router.post(
    "/guest",
    response_model=CNNPredictResponse,
    summary="Klasifikasi tanpa login (foto tidak disimpan ke riwayat)",
)
async def classify_guest(
    photo: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    """Klasifikasi CNN tanpa autentikasi. Foto tetap disimpan di disk tapi tidak ke DB."""
    _, image_bytes = await save_upload_photo(photo, subfolder="guest")
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)

    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
    )
