from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.db.database import get_db
from app.schemas.history_schema import HistoryScanResponse
from app.services.history_service import (
    get_user_history,
    get_history_by_id,
    delete_history_scan,
)
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter(prefix="/history", tags=["History"])


@router.get(
    "/",
    response_model=List[HistoryScanResponse],
    summary="Ambil semua riwayat scan milik user",
)
async def list_history(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await get_user_history(db, current_user.id, limit=limit, offset=offset)


@router.get(
    "/{scan_id}",
    response_model=HistoryScanResponse,
    summary="Ambil detail satu riwayat scan",
)
async def get_history(
    scan_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    scan = await get_history_by_id(db, scan_id, current_user.id)
    if not scan:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")
    return scan


@router.delete(
    "/{scan_id}",
    status_code=204,
    summary="Hapus satu riwayat scan",
)
async def remove_history(
    scan_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    deleted = await delete_history_scan(db, scan_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")
