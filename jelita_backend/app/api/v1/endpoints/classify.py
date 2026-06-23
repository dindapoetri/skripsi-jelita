from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from typing import List
import json

from app.schemas.history_schema import CNNPredictResponse
from app.services.cnn_service import predict_skin_type
from app.services.cbf_service import get_recommendations
from app.services.history_service import create_history_scan
from app.utils.file_utils import save_upload_photo
from app.core.security import get_current_user

router = APIRouter(prefix="/classify", tags=["CNN Classification"])


@router.post(
    "/",
    response_model=CNNPredictResponse,
    summary="Upload foto wajah → klasifikasi CNN → simpan ke riwayat",
)
async def classify_and_save(
    photo: UploadFile = File(...),
    concerns: str = Form(default="[]"),
    current_user: dict = Depends(get_current_user),  # ← dict, bukan User model
):
    # 1. Simpan foto
    image_path, image_bytes = await save_upload_photo(photo, subfolder="scans")

    # 2. CNN inference
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)

    # 3. Parse concerns
    try:
        concerns_list: List[str] = json.loads(concerns)
        if not isinstance(concerns_list, list):
            concerns_list = []
    except (json.JSONDecodeError, ValueError):
        concerns_list = []

    # 4. CBF rekomendasi
    recs = await get_recommendations(
        skin_type=skin_type,
        concerns=concerns_list,
        top_n=5,
    )

    # Flatten snapshot
    snapshot = []
    if hasattr(recs, 'model_dump'):
        for cat_name, products in recs.model_dump().items():
            if isinstance(products, list):
                for p in products:
                    p["category"] = cat_name
                    snapshot.append(p)

    # 5. Simpan ke history_scans via Supabase
    history = await create_history_scan(
        user_id=current_user["id"],
        data={
            "skin_type":                skin_type,
            "cnn_confidence":           confidence,
            "concerns":                 concerns_list,
            "image_url":                image_path,
            "recommendations_snapshot": snapshot,
        }
    )

    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
        image_url=image_path,
        history_id=history.get("id"),
    )


@router.post(
    "/guest",
    response_model=CNNPredictResponse,
    summary="Klasifikasi tanpa login",
)
async def classify_guest(
    photo: UploadFile = File(...),
):
    _, image_bytes = await save_upload_photo(photo, subfolder="guest")
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)

    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
    )