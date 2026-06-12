from fastapi import APIRouter
from app.api.v1.endpoints import auth, recommendations, classify, history

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router)
api_router.include_router(recommendations.router)
api_router.include_router(classify.router)
api_router.include_router(history.router)
