from datetime import datetime
from app.db.database import supabase_admin as supabase

# =========================
# FACE CAPTURE
# =========================
async def save_face_capture(history_id: str, image_url: str):
    res = supabase.table("face_captures").insert({
        "history_id": history_id,
        "image_url": image_url,
        "created_at": datetime.utcnow().isoformat(),
    }).execute()

    return res.data[0]


# =========================
# CLASSIFICATION RESULT
# =========================
async def save_classification_result(
    history_id: str,
    face_capture_id: str,
    skin_type: str,
    confidence: float,
    concerns: list,
):
    res = supabase.table("classification_results").insert({
        "history_id": history_id,
        "face_capture_id": face_capture_id,
        "skin_type": skin_type,
        "confidence_score": confidence,
        "detected_symptoms": concerns,
        "created_at": datetime.utcnow().isoformat(),
    }).execute()

    return res.data[0]


# =========================
# RECOMMENDATIONS
# =========================
async def save_recommendations(classification_result_id: str, products: list):

    print("CLASSIFICATION ID:", classification_result_id)
    print("TOTAL PRODUCTS:", len(products))

    rows = []

    for i, p in enumerate(products):
        print("PRODUCT:", p)

        product_id = p.get("product_id") or p.get("id")

        if not product_id:
            print("SKIP PRODUCT (NO ID)")
            continue

        rows.append({
            "classification_result_id": classification_result_id,
            "product_id": product_id,
            "cbf_score": p.get("score", 0),
            "rank": i + 1,
            "reason_text": p.get("reason", ""),
            "concern_match": p.get("concern_match") or [],
        })

    print("ROWS READY:", len(rows))

    if not rows:
        print("NO DATA TO INSERT")
        return

    res = supabase_admin.table("recommendations").insert(rows).execute()

    print("INSERT RESULT:", res)
    print("CBF INSERT RESPONSE:", res)
    print("CBF INSERT ERROR:", getattr(res, "error", None))
    print("CBF INSERT DATA:", res.data)