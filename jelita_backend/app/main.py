from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import traceback
from supabase import create_client, Client

from app.core.config import settings
from app.api.v1.router import api_router
from app.services.cbf_service import build_product_cache, load_metadata
from app.services.cnn_service import load_cnn_model
from app.db.database import supabase_admin


# ─────────────────────────────
# LIFESPAN (STARTUP EVENT)
# ─────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("=" * 50)
    print(f"  {settings.APP_NAME} v{settings.APP_VERSION}")
    print("=" * 50)

    # ── CNN MODEL ──
    print("[ML] Loading CNN model...")
    load_cnn_model()

    # ── CBF METADATA (VOCAB + IDF) ──
    print("[CBF] Loading metadata (vocab + idf)...")
    await load_metadata()

    # ── PRODUCT CACHE ──
    print("[CBF] Building product cache dari Supabase...")
    await build_product_cache()

    print("[APP] Server siap 🚀")

    yield

    print("[APP] Shutdown complete.")


# ─────────────────────────────
# FASTAPI INIT
# ─────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)


# ─────────────────────────────
# CORS CONFIG
# ─────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────
# ROUTER
# ─────────────────────────────
app.include_router(api_router)


# ─────────────────────────────
# ROOT ENDPOINT
# ─────────────────────────────
@app.get("/", tags=["Root"])
def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs",
    }


# ─────────────────────────────
# HEALTH CHECK
# ─────────────────────────────
@app.get("/health", tags=["Root"])
def health():
    return {"status": "ok"}


# ─────────────────────────────
# GLOBAL ERROR HANDLER (DEV MODE)
# ─────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),
            "detail": traceback.format_exc(),
        }
    )
