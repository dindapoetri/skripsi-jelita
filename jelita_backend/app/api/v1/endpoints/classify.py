from fastapi import APIRouter, Depends, UploadFile, File, Form
import json

from app.schemas.history_schema import CNNPredictResponse
from app.services.cnn_service import predict_skin_type
from app.services.cbf_service import get_recommendations
from app.services.history_service import create_history_scan
from app.utils.file_utils import save_upload_photo
from app.core.security import get_current_user

from app.services.pipeline_service import (
    save_face_capture,
    save_classification_result,
    save_recommendations,
)

router = APIRouter(prefix="/classify", tags=["CNN Classification"])


@router.post("/", response_model=CNNPredictResponse)
async def classify_and_save(
    photo: UploadFile = File(...),
    concerns: str = Form(default="[]"),
    current_user: dict = Depends(get_current_user),
):

    # ======================
    # 1. UPLOAD IMAGE
    # ======================
    image_url, image_bytes = await save_upload_photo(photo, subfolder="scans")

    # ======================
    # 2. CNN PREDICTION
    # ======================
    skin_type, confidence, all_scores = predict_skin_type(image_bytes)

    # ======================
    # 3. PARSE CONCERNS
    # ======================
    try:
        concerns_list = json.loads(concerns)
    except:
        concerns_list = []

    # ======================
    # 4. CREATE HISTORY
    # ======================
    history = await create_history_scan(
        user_id=current_user["id"],
        data={
            "skin_type": skin_type,
            "cnn_confidence": confidence,
            "concerns": concerns_list,
            "image_url": image_url,
        }
    )

    history_id = history["id"]

    # ======================
    # 5. FACE CAPTURE
    # ======================
    face = await save_face_capture(
        history_id=history_id,
        image_url=image_url,
    )

    face_capture_id = face["id"]

    # ======================
    # 6. CLASSIFICATION RESULT
    # ======================
    classification = await save_classification_result(
        history_id=history_id,
        face_capture_id=face_capture_id,
        skin_type=skin_type,
        confidence=confidence,
        concerns=concerns_list,
    )

    classification_id = classification["id"]

    # ======================
    # 7. RECOMMENDATIONS (FIXED FULL)
    # ======================
    recs = await get_recommendations(
        skin_type=skin_type,
        concerns=concerns_list,
        top_n=5,
    )

    products = []

    # flatten safe
    recs_dict = recs.model_dump() if hasattr(recs, "model_dump") else recs

    for _, items in recs_dict.items():
        if not isinstance(items, list):
            continue

        for i, p in enumerate(items):

            # handle object / dict hybrid
            product_id = getattr(p, "id", None) if not isinstance(p, dict) else p.get("id")
            score = getattr(p, "similarity_score", 0.0) if not isinstance(p, dict) else p.get("similarity_score", 0.0)

            if not product_id:
                continue  # safety guard biar tidak gagal insert

            products.append({
                "product_id": product_id,
                "cbf_score": score,
                "rank": i + 1,
                "concern_match": concerns_list if isinstance(concerns_list, list) else [],
            })

    # DEBUG (biar kamu bisa cek kalau masih error)
    print("FINAL PRODUCTS:", products)
    print("CLASSIFICATION ID:", classification_id)

    await save_recommendations(
        classification_result_id=classification_id,
        products=products
    )

    # ======================
    # RESPONSE
    # ======================
    return CNNPredictResponse(
        skin_type=skin_type,
        confidence=confidence,
        all_scores=all_scores,
        image_url=image_url,
        history_id=history_id,
    )


@router.post("/guest", response_model=CNNPredictResponse)
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