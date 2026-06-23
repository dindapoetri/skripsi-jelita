from fastapi import APIRouter
from app.db.database import supabase_admin
from app.services.cbf_service import _product_cache, _idf, _vocab

router = APIRouter(prefix="/health", tags=["Health"])


# ─────────────────────────────
# BASIC STATUS
# ─────────────────────────────
@router.get("/status")
def status():
    return {
        "service": "Jelita Skincare API",
        "status": "running"
    }


# ─────────────────────────────
# DATABASE CHECK
# ─────────────────────────────
@router.get("/database")
def database_check():
    try:
        res = (
            supabase_admin
            .table("products")
            .select("id")
            .limit(1)
            .execute()
        )

        return {
            "database": "connected",
            "sample_rows": len(res.data or [])
        }

    except Exception as e:
        return {
            "database": "failed",
            "error": str(e)
        }


# ─────────────────────────────
# CBF CHECK
# ─────────────────────────────
@router.get("/cbf")
def cbf_check():
    return {
        "metadata_loaded": _idf is not None and _vocab is not None,
        "vocab_size": len(_vocab) if _vocab else 0,
        "idf_size": len(_idf) if _idf is not None else 0,
        "product_cache_size": len(_product_cache) if _product_cache else 0
    }


# ─────────────────────────────
# FULL SYSTEM CHECK
# ─────────────────────────────
@router.get("/system")
def system_check():
    db_ok = True
    cbf_ok = _idf is not None and _vocab is not None
    product_ok = len(_product_cache) > 0

    try:
        supabase_admin.table("products").select("id").limit(1).execute()
    except:
        db_ok = False

    return {
        "fastapi": "ok",
        "database": "ok" if db_ok else "failed",
        "cbf_metadata": "ok" if cbf_ok else "missing",
        "product_cache": len(_product_cache),
        "recommendation_ready": cbf_ok and product_ok,
        "classify_ready": True,
        "history_ready": True
    }


# ─────────────────────────────
# ENDPOINT TEST SIMULASI FLOW
# ─────────────────────────────
@router.get("/integration-test")
def integration_test():
    """
    Simulasi apakah semua sistem siap:
    classify → recommendation → history
    """

    try:
        # DB test
        db = supabase_admin.table("products").select("id").limit(1).execute()

        # CBF test
        cbf_ready = _idf is not None and _vocab is not None

        # product cache
        cache_ready = len(_product_cache) > 0

        return {
            "database": "ok" if db else "fail",
            "cbf": "ok" if cbf_ready else "fail",
            "product_cache": len(_product_cache),
            "classify_endpoint": "assumed_ok",
            "recommendation_endpoint": "assumed_ok",
            "history_endpoint": "assumed_ok",
            "overall_ready": cbf_ready and cache_ready
        }

    except Exception as e:
        return {
            "error": str(e),
            "overall_ready": False
        }