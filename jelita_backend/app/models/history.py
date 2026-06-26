from fastapi import APIRouter, HTTPException
from uuid import UUID

from app.services.history_service import (
    create_history_scan,
    get_user_history,
    get_history_by_id,
    delete_history_scan,
    delete_all_user_history
)

router = APIRouter(prefix="/history", tags=["History"])


# =========================
# CREATE HISTORY SCAN
# =========================
@router.post("")
async def create_scan(user_id: UUID, data: dict):
    try:
        result = await create_history_scan(user_id, data)
        return {
            "message": "success",
            "data": result
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# GET USER HISTORY
# =========================
@router.get("/{user_id}")
async def get_history(user_id: UUID, limit: int = 20, offset: int = 0):
    try:
        result = await get_user_history(user_id, limit, offset)
        return {
            "message": "success",
            "data": result
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# GET HISTORY BY ID
# =========================
@router.get("/{user_id}/{scan_id}")
async def get_history_detail(user_id: UUID, scan_id: int):
    try:
        result = await get_history_by_id(scan_id, user_id)

        if not result:
            raise HTTPException(status_code=404, detail="History tidak ditemukan")

        return {
            "message": "success",
            "data": result
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# DELETE 1 HISTORY
# =========================
@router.delete("/{user_id}/{scan_id}")
async def delete_history(user_id: UUID, scan_id: int):
    try:
        success = await delete_history_scan(scan_id, user_id)

        if not success:
            raise HTTPException(status_code=404, detail="Gagal menghapus / data tidak ada")

        return {
            "message": "deleted successfully"
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================
# DELETE ALL USER HISTORY
# =========================
@router.delete("/{user_id}")
async def delete_all_history(user_id: UUID):
    try:
        deleted_count = await delete_all_user_history(user_id)

        return {
            "message": "success",
            "deleted_count": deleted_count
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))