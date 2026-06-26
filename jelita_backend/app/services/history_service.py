from fastapi import HTTPException
from app.db.database import supabase_admin
from uuid import UUID
from typing import Optional


async def create_history_scan(user_id: UUID, data: dict) -> dict:
    try:
        face_capture_id = None
        image_url = data.get("image_url") or data.get("image_path")
        print("📥 create_history_scan data:", data)
        print("🖼️ image_url:", image_url)
        if image_url:
            face_payload = {
                "device_id": data.get("device_id"),
                "image_url": image_url,
                "storage_path": data.get("storage_path"),
                "is_consented_for_training": data.get("is_consented_for_training", False),
            }
            print("📸 insert face_captures payload:", face_payload)
            face_res = supabase_admin.table("face_captures").insert(face_payload).execute()
            print("📸 face_captures result:", face_res.data)
            if not face_res.data:
                raise HTTPException(
                    status_code=500,
                    detail="Gagal menyimpan data gambar ke face_captures"
                )
            face_capture_id = face_res.data[0]["id"]
        insert_payload = {
            "user_id": str(user_id),
            "skin_type": data.get("skin_type"),
            "confidence_score": data.get("confidence_score"),
            "detected_symptoms": data.get("detected_symptoms", []),
            "concerns": data.get("concerns", []),
            "description": data.get("description"),
            "probabilities": data.get("probabilities", {}),
            "recommendations": data.get("recommendations", []),
            "ideal_ingredients": data.get("ideal_ingredients", []),
            "face_capture_id": face_capture_id,
        }
        print("📝 insert classification_results payload:", insert_payload)
        res = supabase_admin.table("classification_results").insert(insert_payload).execute()
        print("📝 classification_results result:", res.data)
        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal menyimpan riwayat")
        return res.data[0]
    except HTTPException:
        raise
    except Exception as e:
        print("❌ Error simpan riwayat:", str(e))
        raise HTTPException(status_code=500, detail=f"Error simpan riwayat: {str(e)}")


async def get_user_history(user_id: UUID, limit: int = 20, offset: int = 0) -> list:
    try:
        res = supabase_admin.table("classification_results") \
            .select("*, face_captures(image_url)") \
            .eq("user_id", str(user_id)) \
            .order("created_at", desc=True) \
            .range(offset, offset + limit - 1) \
            .execute()

        rows = res.data or []
        return [_flatten_image_url(row) for row in rows]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error ambil riwayat: {str(e)}")


async def get_history_by_id(scan_id: str, user_id: UUID) -> Optional[dict]:
    try:
        res = supabase_admin.table("classification_results") \
            .select("*, face_captures(image_url)") \
            .eq("id", scan_id) \
            .eq("user_id", str(user_id)) \
            .limit(1) \
            .execute()
        rows = res.data or []
        return _flatten_image_url(rows[0]) if rows else None
    except Exception:
        return None


def _flatten_image_url(row: dict) -> dict:
    """Supabase nested select balikin face_captures sebagai dict/list,
    pindahkan image_url-nya jadi field flat di row utama."""
    face_capture = row.pop("face_captures", None)
    if isinstance(face_capture, list):
        face_capture = face_capture[0] if face_capture else None
    if isinstance(face_capture, dict):
        row["image_url"] = face_capture.get("image_url")
    else:
        row["image_url"] = None
    return row


async def delete_history_scan(scan_id: str, user_id: UUID) -> bool:
    try:
        res = supabase_admin.table("classification_results") \
            .delete() \
            .eq("id", scan_id) \
            .eq("user_id", str(user_id)) \
            .execute()
        return bool(res.data)
    except Exception:
        return False


async def delete_all_user_history(user_id: UUID) -> int:
    try:
        res = supabase_admin.table("classification_results") \
            .delete() \
            .eq("user_id", str(user_id)) \
            .execute()
        return len(res.data) if res.data else 0
    except Exception:
        return 0