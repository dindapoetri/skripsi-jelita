"""
CBF (Content-Based Filtering) Service
─────────────────────────────────────
Alur:
1. Load semua produk dari DB satu kali, simpan di memory cache
2. Saat request masuk, buat query_vector dari skin_type + concerns
3. Hitung cosine_similarity antara query_vector dan semua produk
4. Return top-N per kategori
"""

import joblib
import numpy as np
from typing import List, Dict
from sklearn.metrics.pairwise import cosine_similarity
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.models.product import Product
from app.schemas.product_schema import ProductWithScore, CategoryRecommendations


# ─── Cache produk di memori ───────────────────────────────────
_product_cache: List[dict] = []
_tfidf_matrix: np.ndarray | None = None
_vectorizer = None


def load_cbf_model():
    global _vectorizer
    try:
        # Joblib bisa load .joblib langsung, tidak perlu ubah apapun
        loaded = joblib.load(settings.CBF_MODEL_PATH)

        # Cek apakah isinya dict (model + vectorizer sekaligus)
        if isinstance(loaded, dict):
            _vectorizer = loaded.get("vectorizer") or loaded.get("tfidf")
            print(f"[CBF] Loaded dari dict: keys = {list(loaded.keys())}")
        else:
            # Langsung vectorizer
            _vectorizer = loaded
            
        print(f"[CBF] Model loaded dari {settings.CBF_MODEL_PATH}")
    except FileNotFoundError:
        print(f"[CBF] WARNING: File tidak ditemukan, pakai fallback TF-IDF")
        from sklearn.feature_extraction.text import TfidfVectorizer
        _vectorizer = TfidfVectorizer(max_features=5000, ngram_range=(1, 2))


async def build_product_cache(db: AsyncSession):
    """Ambil semua produk dari DB dan buat TF-IDF matrix."""
    global _product_cache, _tfidf_matrix, _vectorizer

    result = await db.execute(select(Product))
    products = result.scalars().all()

    if not products:
        print("[CBF] WARNING: Tidak ada produk di database!")
        return

    _product_cache = [
        {
            "id": p.id,
            "name": p.name,
            "brand": p.brand,
            "category": p.category,
            "description_clean": p.description_clean or "",
            "how_to_use": p.how_to_use or "",
            "suitable_for": p.suitable_for or "",
            "image_url": p.image_url,
        }
        for p in products
    ]

    # Buat corpus: gabungan semua teks per produk
    corpus = [
        _build_product_text(p) for p in _product_cache
    ]

    if _vectorizer is None:
        load_cbf_model()

    # Fit atau transform tergantung apakah vectorizer sudah di-fit
    try:
        _tfidf_matrix = _vectorizer.transform(corpus)
    except Exception:
        # Vectorizer belum di-fit (fallback), fit sekarang
        _tfidf_matrix = _vectorizer.fit_transform(corpus)

    print(f"[CBF] Cache dibangun: {len(_product_cache)} produk, matrix shape: {_tfidf_matrix.shape}")


def _build_product_text(p: dict) -> str:
    """Gabungkan field produk menjadi satu string untuk TF-IDF."""
    parts = [
        p.get("suitable_for", ""),
        p.get("description_clean", ""),
        p.get("how_to_use", ""),
        p.get("category", ""),
    ]
    return " ".join(filter(None, parts)).lower()


def _build_query_text(skin_type: str, concerns: List[str]) -> str:
    """Buat query string dari skin_type + concerns pengguna."""
    skin_map = {
        "normal": "kulit normal",
        "oily": "kulit berminyak minyak berlebih",
        "dry": "kulit kering kelembapan",
        "combination": "kulit kombinasi t-zone",
        "sensitive": "kulit sensitif kemerahan iritasi",
    }
    skin_text = skin_map.get(skin_type.lower(), skin_type)
    concerns_text = " ".join(concerns)
    return f"{skin_text} {concerns_text}".lower().strip()


async def get_recommendations(
    skin_type: str,
    concerns: List[str],
    top_n: int = 5,
    db: AsyncSession = None,
) -> CategoryRecommendations:
    """
    Return top-N rekomendasi per kategori produk.
    """
    global _product_cache, _tfidf_matrix, _vectorizer

    # Rebuild cache jika kosong
    if not _product_cache or _tfidf_matrix is None:
        if db is None:
            raise ValueError("DB diperlukan untuk build cache pertama kali")
        await build_product_cache(db)

    if not _product_cache:
        return CategoryRecommendations()

    # Buat query vector
    query_text = _build_query_text(skin_type, concerns)
    query_vec = _vectorizer.transform([query_text])

    # Hitung cosine similarity
    scores = cosine_similarity(query_vec, _tfidf_matrix).flatten()

    # Pasangkan skor ke produk
    scored_products = [
        {**_product_cache[i], "similarity_score": float(scores[i])}
        for i in range(len(_product_cache))
    ]

    # Kategori valid
    categories = {
        "facial_wash": [],
        "toner": [],
        "moisturizer": [],
        "sunscreen": [],
    }

    for p in scored_products:
        cat = _normalize_category(p["category"])
        if cat in categories:
            categories[cat].append(p)

    # Sort tiap kategori dan ambil top-N
    result = {}
    for cat, products in categories.items():
        top = sorted(products, key=lambda x: x["similarity_score"], reverse=True)[:top_n]
        result[cat] = [ProductWithScore(**p) for p in top]

    return CategoryRecommendations(**result)


def _normalize_category(raw: str) -> str:
    """Normalisasi nama kategori dari DB ke key yang konsisten."""
    raw = raw.lower().strip().replace(" ", "_").replace("-", "_")
    mapping = {
        "facial_wash": "facial_wash",
        "face_wash": "facial_wash",
        "sabun_muka": "facial_wash",
        "toner": "toner",
        "toning": "toner",
        "moisturizer": "moisturizer",
        "pelembap": "moisturizer",
        "moisturiser": "moisturizer",
        "sunscreen": "sunscreen",
        "sun_screen": "sunscreen",
        "spf": "sunscreen",
        "sunblock": "sunscreen",
    }
    return mapping.get(raw, raw)


def invalidate_cache():
    """Paksa rebuild cache (panggil setelah produk di-update)."""
    global _product_cache, _tfidf_matrix
    _product_cache = []
    _tfidf_matrix = None
    print("[CBF] Cache di-invalidate, akan rebuild saat request berikutnya")
