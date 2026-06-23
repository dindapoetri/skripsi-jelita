from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List

from app.schemas.history_schema import HistoryScanResponse
from app.services.history_service import (
    get_user_history,
    get_history_by_id,
    delete_history_scan,
    delete_all_user_history,
)
from app.core.security import get_current_user

router = APIRouter(prefix="/history", tags=["History"])


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
    scan_id: int,
    current_user: dict = Depends(get_current_user),
):
    scan = await get_history_by_id(scan_id, current_user["id"])
    if not scan:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")
    return scan


@router.delete(
    "/all",
    summary="Hapus semua riwayat scan user",
)
async def remove_all_history(
    current_user: dict = Depends(get_current_user),
):
    deleted = await delete_all_user_history(current_user["id"])
    return {"message": f"{deleted} riwayat berhasil dihapus"}


@router.delete(
    "/{scan_id}",
    status_code=204,
    summary="Hapus satu riwayat scan",
)
async def remove_history(
    scan_id: int,
    current_user: dict = Depends(get_current_user),
):
    deleted = await delete_history_scan(scan_id, current_user["id"])
    if not deleted:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")