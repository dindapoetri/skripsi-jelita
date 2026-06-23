from fastapi import APIRouter
from app.api.v1.endpoints import auth, recommendations, classify, history, health

# Prefix /api/v1 — semua endpoint jadi:
# /api/v1/auth/register
# /api/v1/auth/login
# /api/v1/classify/
# /api/v1/history/
# /api/v1/recommendations/
# /api/v1/health/
api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router)
api_router.include_router(classify.router)
api_router.include_router(history.router)
api_router.include_router(recommendations.router)
api_router.include_router(health.router)