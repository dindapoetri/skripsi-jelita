from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os

from app.core.config import settings
from app.api.v1.router import api_router
from app.db.database import create_tables
from app.services.cbf_service import load_cbf_model
from app.services.cnn_service import load_cnn_model


# ─── Lifespan: startup & shutdown ────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("=" * 50)
    print(f"  {settings.APP_NAME} v{settings.APP_VERSION}")
    print("=" * 50)

    # 1. Buat tabel DB jika belum ada
    print("[DB] Membuat tabel...")
    await create_tables()
    print("[DB] Tabel siap.")

    # 2. Load model ML
    print("[ML] Loading CNN model...")
    load_cnn_model()

    print("[ML] Loading CBF vectorizer...")
    load_cbf_model()

    print("[APP] Server siap!")
    yield

    print("[APP] Shutdown.")


# ─── Inisialisasi app ─────────────────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="""
## Jelita Skincare API

Backend untuk aplikasi rekomendasi skincare berbasis CNN + CBF.

### Fitur:
- 🔐 **Auth**: Register & Login dengan JWT
- 🤖 **CNN**: Klasifikasi jenis kulit dari foto wajah
- 💡 **CBF**: Rekomendasi produk berdasarkan Content-Based Filtering
- 📋 **History**: Riwayat scan & rekomendasi per user
- 📷 **Upload**: Simpan foto ke server

### Alur penggunaan:
1. Register / Login → dapat token JWT
2. Upload foto wajah ke `/classify/` → dapat skin_type
3. Hasil otomatis disimpan ke riwayat
4. Ambil rekomendasi manual via `/recommendations/`
""",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# 
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list + ["*"],  # ubah "*" ke domain spesifik di produksi
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Static files (foto yang di-upload) ───────────────────────
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# ─── Routes ───────────────────────────────────────────────────
app.include_router(api_router)


@app.get("/", tags=["Root"])
async def root():
    return {
        "message": f"Selamat datang di {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "docs": "/docs",
    }


@app.get("/health", tags=["Root"])
async def health_check():
    return {"status": "ok", "app": settings.APP_NAME}
