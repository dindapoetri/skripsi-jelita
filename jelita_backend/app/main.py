from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import traceback

from app.core.config import settings
from app.api.v1.router import api_router
from app.services.cbf_service import build_product_cache, load_metadata, debug_category_distribution
from app.services.cnn_service import load_cnn_model


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("=" * 50)
    print(f"  {settings.APP_NAME} v{settings.APP_VERSION}")
    print("=" * 50)

    print("[ML] Loading CNN model...")
    load_cnn_model()

    print("[CBF] Loading metadata (vocab + idf)...")
    await load_metadata()

    print("[CBF] Building product cache dari Supabase...")
    await build_product_cache()
    
    # SEMENTARA
    debug_category_distribution()
    
    print("[APP] Server siap 🚀")

    yield

    print("[APP] Shutdown complete.")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ROUTER
app.include_router(api_router)


# =========================
# ROOT ENDPOINT (WAJIB)
# =========================
@app.get("/", tags=["Root"])
def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs",
    }


# =========================
# HEALTH CHECK (WAJIB)
# =========================
@app.get("/health", tags=["Root"])
def health():
    return {"status": "ok"}


# =========================
# GLOBAL ERROR HANDLER
# =========================
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),
            "detail": traceback.format_exc(),
        }
    )