import joblib
import numpy as np
import pandas as pd
from pathlib import Path
from typing import List, Dict, Any
from scipy.sparse import load_npz
from sklearn.metrics.pairwise import cosine_similarity

from app.db.database import supabase_admin
from app.schemas.product_schema import ProductWithScore, CategoryRecommendations

# ─────────────────────────────
# KONFIGURASI PATH & KOLOM ALIGNMENT
# ─────────────────────────────
ARTIFACTS_DIR = Path("artifacts")
VECTORIZER_PATH = ARTIFACTS_DIR / "cbf_vectorizer.joblib"
MATRIX_PATH = ARTIFACTS_DIR / "tfidf_matrix.npz"

# CSV sumber yang PERSIS dipakai untuk membangun tfidf_matrix.npz.
# Row ke-i di CSV ini HARUS sama dengan row ke-i di tfidf_matrix.npz.
SOURCE_CSV_PATH = ARTIFACTS_DIR / "products_final_for_supabase.csv"


# ─────────────────────────────
# GLOBAL CACHE
# ─────────────────────────────
_vectorizer = None
_tfidf_matrix = None                    # scipy.sparse csr_matrix, shape (N, V)
_row_index_by_url: Dict[str, int] = {}  # url -> baris di _tfidf_matrix
_product_cache: List[Dict[str, Any]] = []      # sejajar 1:1 dengan _tfidf_matrix


def _normalize_url(url: str) -> str:
    """Normalisasi ringan supaya perbedaan trailing slash/whitespace tidak
    membuat url yang sebenarnya sama dianggap beda."""
    return str(url).strip().rstrip('/').lower()


# ─────────────────────────────
# LOAD CBF MODEL (vectorizer + matrix + pemetaan url->row)
# ─────────────────────────────
def load_cbf_model():
    global _vectorizer, _tfidf_matrix, _row_index_by_url

    if not VECTORIZER_PATH.exists():
        raise RuntimeError(f"[CBF] Vectorizer tidak ditemukan: {VECTORIZER_PATH}")
    if not MATRIX_PATH.exists():
        raise RuntimeError(f"[CBF] tfidf_matrix tidak ditemukan: {MATRIX_PATH}")
    if not SOURCE_CSV_PATH.exists():
        raise RuntimeError(
            f"[CBF] CSV sumber untuk pemetaan url->row tidak ditemukan: {SOURCE_CSV_PATH}. "
            f"File ini WAJIB ada dan harus persis CSV yang dipakai membangun tfidf_matrix.npz."
        )

    _vectorizer = joblib.load(VECTORIZER_PATH)
    _tfidf_matrix = load_npz(MATRIX_PATH)

    source_df = pd.read_csv(SOURCE_CSV_PATH)

    if len(source_df) != _tfidf_matrix.shape[0]:
        raise RuntimeError(
            f"[CBF] MISALIGNMENT: CSV sumber punya {len(source_df)} baris, "
            f"tfidf_matrix punya {_tfidf_matrix.shape[0]} baris. Ini TIDAK BOLEH beda. "
            f"Pastikan SOURCE_CSV_PATH adalah CSV yang sama persis dipakai saat fit vectorizer."
        )

    if source_df['url'].isna().any():
        raise RuntimeError("[CBF] Ada url NULL/kosong di CSV sumber -- kunci alignment tidak valid.")

    normalized_urls = source_df['url'].apply(_normalize_url)
    if normalized_urls.duplicated().any():
        n_dup = int(normalized_urls.duplicated().sum())
        raise RuntimeError(
            f"[CBF] Ada {n_dup} url duplikat (setelah normalisasi) di CSV sumber -- "
            f"kunci alignment jadi ambigu. Cek data sebelum lanjut."
        )

    # row ke-i CSV -> row ke-i matrix. Bangun pemetaan url -> row index.
    _row_index_by_url = {
        url: idx for idx, url in enumerate(normalized_urls.tolist())
    }

    print(f"[CBF] vectorizer loaded: {len(_vectorizer.get_feature_names_out())} vocabulary")
    print(f"[CBF] tfidf_matrix loaded: shape={_tfidf_matrix.shape}")
    print(f"[CBF] pemetaan url->row dibangun: {len(_row_index_by_url)} entri")


# ─────────────────────────────
# LOAD PRODUCTS (dari Supabase, DISELARASKAN eksplisit ke tfidf_matrix)
# ─────────────────────────────
async def load_products():
    global _product_cache

    if not _row_index_by_url:
        raise RuntimeError("[CBF] load_cbf_model() belum dipanggil / gagal -- pemetaan url kosong.")

    PAGE_SIZE = 1000
    all_products: List[Dict[str, Any]] = []
    offset = 0

    while True:
        res = supabase_admin.table("products") \
        .select(
            """
            id,
            product_name,
            brand,
            category,
            description,
            description_clean,
            ingredients_clean,
            concerns_str,
            suitable_labels,
            url
            """
        ) \
            .range(offset, offset + PAGE_SIZE - 1) \
            .execute()

        rows = res.data or []
        all_products.extend(rows)

        if len(rows) < PAGE_SIZE:
            break
        offset += PAGE_SIZE

    if not all_products:
        raise RuntimeError("[CBF] Tidak ada produk aktif di Supabase.")

    # ── Debug: kolom apa saja yang BENAR-BENAR dibalikin Supabase.
    # Kalau 'concerns_str' / 'suitable_labels' tidak muncul di sini padahal
    # sudah ada di tabel, itu tanda schema cache PostgREST belum di-reload,
    # atau backend nyambung ke project Supabase yang beda.
    print(f"[CBF] DEBUG kolom hasil fetch (baris pertama): {sorted(all_products[0].keys())}")

    REQUIRED_COLUMNS = [
        "id", "product_name", "brand", "category", "url",
        "description", "description_clean", "ingredients_clean",
        "concerns_str", "suitable_labels",
    ]
    missing_columns = [c for c in REQUIRED_COLUMNS if c not in all_products[0]]
    if missing_columns:
        raise RuntimeError(
            f"[CBF] Kolom {missing_columns} tidak ada di response Supabase, padahal diminta di .select(). "
            f"Kolom yang benar-benar kebalik: {sorted(all_products[0].keys())}. "
            f"Kemungkinan penyebab: (1) PostgREST schema cache belum di-reload setelah kolom baru "
            f"ditambahkan -- jalankan `NOTIFY pgrst, 'reload schema';` di SQL Editor atau tombol "
            f"'Reload schema' di Dashboard > Settings > API, atau (2) backend ini nyambung ke project "
            f"Supabase yang beda dari yang kamu edit (cek SUPABASE_URL di .env)."
        )

    # ── Validasi alignment SEBELUM dipakai, bukan sesudah ──
    supabase_urls_raw = [p.get("url") for p in all_products]
    if any(u is None or not str(u).strip() for u in supabase_urls_raw):
        n_null = sum(1 for u in supabase_urls_raw if u is None or not str(u).strip())
        raise RuntimeError(
            f"[CBF] {n_null} produk di Supabase punya url NULL/kosong -- "
            f"tidak bisa diselaraskan ke tfidf_matrix. Perbaiki data dulu."
        )

    supabase_urls = {_normalize_url(u) for u in supabase_urls_raw}
    matrix_urls = set(_row_index_by_url.keys())

    missing_in_matrix = supabase_urls - matrix_urls
    missing_in_supabase = matrix_urls - supabase_urls

    if missing_in_matrix:
        raise RuntimeError(
            f"[CBF] {len(missing_in_matrix)} produk di Supabase punya url yang TIDAK ADA "
            f"di tfidf_matrix. Contoh: {list(missing_in_matrix)[:5]}. "
            f"Kemungkinan ada produk baru ditambah manual tanpa vector -- "
            f"regenerate artifact atau nonaktifkan produk ini dulu."
        )
    if missing_in_supabase:
        print(f"[CBF] WARNING: {len(missing_in_supabase)} baris di tfidf_matrix "
              f"tidak punya produk aktif yang cocok di Supabase (mungkin sudah dihapus/nonaktif). "
              f"Baris ini akan diabaikan.")

    # ── Bangun _product_cache SEJAJAR dengan urutan _tfidf_matrix ──
    n_rows = _tfidf_matrix.shape[0]
    cache_by_row: List[Dict[str, Any]] = [None] * n_rows

    for p in all_products:
        norm_url = _normalize_url(p["url"])
        row_idx = _row_index_by_url.get(norm_url)
        if row_idx is None:
            continue  # sudah ditangani di assert missing_in_matrix di atas
        cache_by_row[row_idx] = {
            "id": p["id"],
            "name": p["product_name"],
            "brand": p["brand"],
            "category": p["category"],
            "url": p["url"],
            "description": p["description"],
            "description_clean": p["description_clean"],
            "ingredients_clean": p["ingredients_clean"],
            "concerns_str": p.get("concerns_str"),
            "suitable_labels": p.get("suitable_labels"),
        }

    filled_rows = [i for i, v in enumerate(cache_by_row) if v is not None]
    if len(filled_rows) != len(all_products):
        raise RuntimeError(
            f"[CBF] Inkonsistensi setelah mapping: {len(all_products)} produk di-fetch, "
            f"tapi {len(filled_rows)} baris cache terisi. Cek duplikat url di Supabase."
        )

    _product_cache = cache_by_row  # boleh mengandung None di baris yang produknya tidak aktif

    print(f"[CBF] {len(filled_rows)}/{n_rows} baris tfidf_matrix punya produk aktif yang cocok.")


# ─────────────────────────────
# QUERY BUILDER
# ─────────────────────────────
SKIN_TYPE_QUERY_MAP = {
    "normal":      "normal balanced skin",
    "oily":        "oily acne sebum oil",
    "dry":         "dry dehydrated moisture",
    "combination": "combination mixed skin",
    "acne":        "acne breakout pimple salicylic acid niacinamide",  # FIX: sebelumnya tidak ada
    "sensitive":   "sensitive irritation redness",
}


def _build_query_text(skin_type: str, concerns: List[str]) -> str:
    base = SKIN_TYPE_QUERY_MAP.get(skin_type.lower(), skin_type)
    return f"{base} {' '.join(concerns or [])}".lower()


# ─────────────────────────────
# HYBRID SCORING & CATEGORY NORMALIZER (tidak berubah dari versi lama)
# ─────────────────────────────
def _hybrid_score(base_score: float, product: dict, skin_type: str) -> float:
    labels = product.get("suitable_labels")

    if isinstance(labels, str):
        labels = [x.strip().lower() for x in labels.split(",") if x.strip()]
    else:
        labels = labels or []

    skin_match = 1.0 if skin_type.lower() in labels else 0.3
    return base_score * 0.6 + skin_match * 0.4


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
async def get_recommendations(skin_type: str, concerns: List[str], top_n: int = 5):
    if _vectorizer is None or _tfidf_matrix is None:
        raise RuntimeError("[CBF] Model belum di-load. Panggil load_cbf_model() saat startup.")
    if not _product_cache:
        await load_products()

    query_text = _build_query_text(skin_type, concerns)
    query_vec = _vectorizer.transform([query_text])  # sparse, shape (1, V)

    scores = cosine_similarity(query_vec, _tfidf_matrix).flatten()  # shape (N,)

    scored_products = []
    for i, product in enumerate(_product_cache):
        if product is None:  # baris matrix tanpa produk aktif yang cocok
            continue
        scored_products.append({
            **product,
            "score": _hybrid_score(float(scores[i]), product, skin_type),
        })

    categories = {"facial_wash": [], "toner": [], "moisturizer": [], "sunscreen": []}
    for p in scored_products:
        cat = _normalize_category(p.get("category", ""))
        if cat in categories:
            categories[cat].append(p)

    def _to_str_list(raw) -> List[str]:
        if isinstance(raw, list):
            return [str(x).strip() for x in raw if str(x).strip()]
        if isinstance(raw, str):
            return [x.strip() for x in raw.split(",") if x.strip()]
        return []

    def _to_product_with_score(item: dict) -> dict:
        return {
            "id": item["id"],
            "name": item.get("name", ""),
            "brand": item.get("brand"),
            "category": item.get("category"),
            "description_clean": item.get("description_clean") or item.get("description") or None,
            "suitable_for": item.get("suitable_labels") or None,  # schema: str, bukan list
            "image_url": item.get("image_url"),
            "concerns": _to_str_list(item.get("concerns_str")),
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
                "product_id": item["id"],
                "score": item["similarity_score"],
                "rank": i + 1,
                "category": category,
            })
    return flat


def invalidate_cache():
    """Kosongkan cache produk supaya panggilan get_recommendations() berikutnya
    memaksa load_products() jalan ulang dan ambil data terbaru dari Supabase."""
    global _product_cache
    _product_cache = []