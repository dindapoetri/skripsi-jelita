from fastapi import HTTPException
from supabase import create_client
from dotenv import load_dotenv
import os

load_dotenv()

supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)


async def create_history_scan(user_id: int, data: dict) -> dict:
    try:
        res = supabase.table("history_scans").insert({
            "user_id":                  user_id,
            "skin_type":                data.get("skin_type"),
            "cnn_confidence":           data.get("cnn_confidence"),
            "concerns":                 data.get("concerns", []),
            "image_url":                data.get("image_url"),
            "recommendations_snapshot": data.get("recommendations_snapshot", []),
        }).execute()

        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal menyimpan riwayat")

        return res.data[0]

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error simpan riwayat: {str(e)}")


async def get_user_history(user_id: int, limit: int = 20, offset: int = 0) -> list:
    try:
        res = supabase.table("history_scans")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()
        return res.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error ambil riwayat: {str(e)}")


async def get_history_by_id(scan_id: int, user_id: int) -> dict | None:
    try:
        res = supabase.table("history_scans")\
            .select("*")\
            .eq("id", scan_id)\
            .eq("user_id", user_id)\
            .limit(1)\
            .execute()
        return res.data[0] if res.data else None
    except Exception:
        return None


async def delete_history_scan(scan_id: int, user_id: int) -> bool:
    try:
        res = supabase.table("history_scans")\
            .delete()\
            .eq("id", scan_id)\
            .eq("user_id", user_id)\
            .execute()
        return bool(res.data)
    except Exception:
        return False


async def delete_all_user_history(user_id: int) -> int:
    try:
        res = supabase.table("history_scans")\
            .delete()\
            .eq("user_id", user_id)\
            .execute()
        return len(res.data) if res.data else 0
    except Exception:
        return 0