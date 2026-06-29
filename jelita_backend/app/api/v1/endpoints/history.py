from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from typing import List, Optional, Dict
from pydantic import BaseModel
import uuid

from app.schemas.history_schema import HistoryScanResponse
from app.services.history_service import (
    create_history_scan,
    get_user_history,
    get_history_by_id,
    delete_history_scan,
    delete_all_user_history,
)
from app.core.security import get_current_user
from app.db.database import supabase_admin

router = APIRouter(prefix="/history", tags=["History"])

BUCKET_NAME = "face-captures"  # sesuaikan nama bucket Supabase Storage kamu


class SaveScanRequest(BaseModel):
    skin_type: str
    confidence_score: float
    detected_symptoms: List[str] = []
    concerns: List[str] = []
    description: Optional[str] = None
    probabilities: Dict[str, float] = {}
    recommendations: List[str] = []
    ideal_ingredients: List[str] = []
    image_url: Optional[str] = None
    device_id: Optional[str] = None
    is_consented_for_training: bool = False


@router.post(
    "/upload-image",
    summary="Upload foto hasil scan ke Supabase Storage, balikin image_url",
)
async def upload_scan_image(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    try:
        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        file_path = f"{current_user['id']}/{uuid.uuid4()}.{ext}"
        content = await file.read()

        supabase_admin.storage.from_(BUCKET_NAME).upload(
            file_path,
            content,
            file_options={"content-type": file.content_type or "image/jpeg"},
        )

        public_url = supabase_admin.storage.from_(BUCKET_NAME).get_public_url(file_path)

        return {"image_url": public_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal upload gambar: {str(e)}")


@router.post(
    "/",
    summary="Simpan hasil klasifikasi CNN (on-device) ke riwayat",
)
async def save_scan(
    data: SaveScanRequest,
    current_user: dict = Depends(get_current_user),
):
    result = await create_history_scan(
        user_id=current_user["id"],
        data=data.model_dump(),
    )
    return result


@router.get(
    "/",
    response_model=List[HistoryScanResponse],
    summary="Ambil semua riwayat scan milik user",
)
async def list_history(
    limit:  int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    return await get_user_history(
        user_id=current_user["id"],
        limit=limit,
        offset=offset,
    )


@router.get(
    "/{scan_id}",
    response_model=HistoryScanResponse,
    summary="Ambil detail satu riwayat scan",
)
async def get_history(
    scan_id: str,
    current_user: dict = Depends(get_current_user),
):
    scan = await get_history_by_id(scan_id, current_user["id"])
    if not scan:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")
    return scan


@router.delete("/all", summary="Hapus semua riwayat scan user")
async def remove_all_history(current_user: dict = Depends(get_current_user)):
    deleted = await delete_all_user_history(current_user["id"])
    return {"message": f"{deleted} riwayat berhasil dihapus"}


@router.delete("/{scan_id}", status_code=204, summary="Hapus satu riwayat scan")
async def remove_history(scan_id: str, current_user: dict = Depends(get_current_user)):
    deleted = await delete_history_scan(scan_id, current_user["id"])
    if not deleted:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")