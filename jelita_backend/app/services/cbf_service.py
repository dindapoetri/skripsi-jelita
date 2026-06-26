import numpy as np
import json
from typing import List, Dict, Any
from sklearn.metrics.pairwise import cosine_similarity

from app.db.database import supabase, supabase_admin
from app.schemas.product_schema import ProductWithScore, CategoryRecommendations

# ─────────────────────────────
# GLOBAL CACHE
# ─────────────────────────────
_product_cache: List[Dict[str, Any]] = []
_product_matrix: np.ndarray | None = None

_vocab: Dict[str, int] = {}
_idf: np.ndarray | None = None


# ─────────────────────────────
# LOAD CBF METADATA (TF-IDF)
# ─────────────────────────────
async def load_metadata():
    global _vocab, _idf

    res = supabase_admin.table("cbf_metadata").select("key, value").execute()
    rows = res.data or []

    if not rows:
        print("[CBF] WARNING: cbf_metadata kosong di database")
        return

    for item in rows:
        if item.get("key") != "tfidf_vocab":
            continue

        raw = item.get("value")

        try:
            payload = json.loads(raw) if isinstance(raw, str) else (raw or {})
        except Exception as e:
            print(f"[CBF] ERROR parsing metadata: {e}")
            return

        vocab_list = payload.get("vocabulary", [])
        idf_list = payload.get("idf", [])

        if not vocab_list or not idf_list:
            print("[CBF] ERROR: vocabulary atau idf kosong")
            return

        _vocab = {token: idx for idx, token in enumerate(vocab_list)}
        _idf = np.array(idf_list, dtype=float)

        print(f"[CBF] metadata loaded: vocab={len(_vocab)}, idf={len(_idf)}")
        return

    print("[CBF] WARNING: tfidf_vocab tidak ditemukan")


# ─────────────────────────────
# LOAD PRODUCT CACHE
# ─────────────────────────────
async def build_product_cache():
    global _product_cache, _product_matrix
 
    PAGE_SIZE = 1000
    all_products: List[Dict[str, Any]] = []
    offset = 0
 
    while True:
        res = supabase_admin.table("products") \
            .select(
                "id, product_name, brand, category, url, skin_types, "
                "tfidf_vector, is_active, description, concerns"
            ) \
            .eq("is_active", True) \
            .range(offset, offset + PAGE_SIZE - 1) \
            .execute()
 
        rows = res.data or []
        all_products.extend(rows)
 
        print(f"[CBF] fetched page offset={offset}, rows={len(rows)}, total_so_far={len(all_products)}")
 
        if len(rows) < PAGE_SIZE:
            break
 
        offset += PAGE_SIZE
 
    _product_cache = [
        {
            "id": p["id"],
            "name": p.get("product_name", ""),
            "brand": p.get("brand", ""),
            "category": p.get("category", ""),
            "url": p.get("url", ""),
            "skin_types": p.get("skin_types") or [],
            "description": p.get("description") or "",
            "concerns": p.get("concerns") or [],
            "vector": p.get("tfidf_vector"),
        }
        for p in all_products
        if p.get("tfidf_vector") is not None
    ]
 
    if not _product_cache:
        print("[CBF] ERROR: product cache kosong")
        return
 
    _product_matrix = np.array(
        [p["vector"] for p in _product_cache],
        dtype=float
    )
 
    print(f"[CBF] products loaded: {len(_product_cache)} (dari total {len(all_products)} baris ter-fetch)")
 


# ─────────────────────────────
# QUERY BUILDER
# ─────────────────────────────
def _build_query_text(skin_type: str, concerns: List[str]) -> str:
    skin_map = {
        "normal": "normal balanced skin",
        "oily": "oily acne sebum oil",
        "dry": "dry dehydrated moisture",
        "combination": "combination mixed skin",
        "sensitive": "sensitive irritation redness",
    }

    base = skin_map.get(skin_type.lower(), skin_type)
    return f"{base} {' '.join(concerns or [])}".lower()


# ─────────────────────────────
# QUERY VECTOR BUILDER
# ─────────────────────────────
def _build_query_vector(text: str) -> np.ndarray:
    if not _vocab or _idf is None:
        raise RuntimeError("CBF metadata belum di-load")

    vec = np.zeros(len(_vocab), dtype=float)

    for token in text.split():
        if token in _vocab:
            vec[_vocab[token]] += 1.0

    vec = vec * _idf

    norm = np.linalg.norm(vec)
    return vec / norm if norm > 0 else vec


# ─────────────────────────────
# HYBRID SCORING
# ─────────────────────────────
def _hybrid_score(base_score: float, product: dict, skin_type: str) -> float:
    skin_match = 1.0 if skin_type.lower() in (product.get("skin_types") or []) else 0.3
    return base_score * 0.6 + skin_match * 0.4


# ─────────────────────────────
# CATEGORY NORMALIZER
# ─────────────────────────────
def _normalize_category(cat: str) -> str:
    if not cat:
        return ""

    cat = cat.lower().strip()

    mapping = {
        "face_wash": "facial_wash",
        "facial_wash": "facial_wash",
        "toner": "toner",
        "moisturizer": "moisturizer",
        "sunscreen": "sunscreen",
    }

    return mapping.get(cat, "")


# ─────────────────────────────
# MAIN RECOMMENDATION ENGINE
# ─────────────────────────────
async def get_recommendations(
    skin_type: str,
    concerns: List[str],
    top_n: int = 5,
):
 
    global _product_cache, _product_matrix
 
    if not _product_cache:
        await build_product_cache()
 
    if _idf is None or not _vocab:
        await load_metadata()
 
    if _product_matrix is None:
        raise RuntimeError("Product matrix belum tersedia")
 
    query_text = _build_query_text(skin_type, concerns)
    query_vec = _build_query_vector(query_text)
 
    scores = cosine_similarity([query_vec], _product_matrix).flatten()
 
    scored_products = [
        {
            **_product_cache[i],
            "score": _hybrid_score(scores[i], _product_cache[i], skin_type)
        }
        for i in range(len(_product_cache))
    ]
 
    categories = {
        "facial_wash": [],
        "toner": [],
        "moisturizer": [],
        "sunscreen": [],
    }
 
    for p in scored_products:
        cat = _normalize_category(p.get("category", ""))
        if cat in categories:
            categories[cat].append(p)
 
    def _to_product_with_score(item: dict) -> dict:
        # Mapping field cache -> field yang dikenal schema ProductWithScore.
        # "vector" & raw "score"/"description" sengaja tidak ikut nama
        # asli, supaya tidak nyangkut sbg extra field yang tidak dikenal.
        return {
            "id": item["id"],
            "name": item.get("name", ""),
            "brand": item.get("brand"),
            "category": item.get("category"),
            "description_clean": item.get("description") or None,
            "suitable_for": item.get("suitable_for"),
            "image_url": item.get("image_url"),
            "skin_types": item.get("skin_types") or [],
            "concerns": item.get("concerns") or [],
            "similarity_score": item.get("score", 0.0),
        }
 
    result = {
        cat: [
            ProductWithScore(**_to_product_with_score(item))
            for item in sorted(items, key=lambda x: x["score"], reverse=True)[:top_n]
        ]
        for cat, items in categories.items()
    }
 
    return CategoryRecommendations(**result)
 

def flatten_recommendations(result: CategoryRecommendations):
    data = result.model_dump()

    flat = []

    for category, items in data.items():
        for i, item in enumerate(items):
            flat.append({
                "product_id": item.id,
                "score": item.similarity_score,
                "rank": i + 1,
                "category": category,
            })

    return flat

# ─────────────────────────────
# CACHE INVALIDATION
# ─────────────────────────────
def invalidate_cache():
    global _product_cache, _product_matrix
    _product_cache = []
    _product_matrix = None
    
# DEBUG SEMENTARA
def debug_category_distribution():
    from collections import Counter
 
    raw_categories = Counter(p.get("category") for p in _product_cache)
    normalized_categories = Counter(
        _normalize_category(p.get("category", "")) for p in _product_cache
    )
 
    print(f"[CBF DEBUG] total produk di cache: {len(_product_cache)}")
    print(f"[CBF DEBUG] kategori MENTAH (raw, sebelum normalize): {dict(raw_categories)}")
    print(f"[CBF DEBUG] kategori SETELAH normalize: {dict(normalized_categories)}")
 
    # tampilkan beberapa contoh produk yang gagal dinormalisasi (cat == "")
    gagal = [p.get("category") for p in _product_cache if _normalize_category(p.get("category", "")) == ""]
    if gagal:
        print(f"[CBF DEBUG] {len(gagal)} produk GAGAL dinormalisasi, contoh nilai mentahnya: {gagal[:10]}")
    else:
        print("[CBF DEBUG] semua produk berhasil dinormalisasi ke salah satu dari 4 kategori.")
 