from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, EmailStr
from dotenv import load_dotenv

from app.schemas.auth_schema import UserRegister, UserLogin, TokenResponse, UserResponse
from app.services.user_service import create_user, authenticate_user, get_user_by_email
from app.core.security import create_access_token, get_current_user

load_dotenv()

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister):
    user = await create_user(data)
    token = create_access_token({"sub": str(user["id"])})
    return TokenResponse(
        access_token=token,
        user=UserResponse(**user),
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: UserLogin):
    user = await authenticate_user(data.email, data.password)
    token = create_access_token({"sub": str(user["id"])})
    return TokenResponse(
        access_token=token,
        user=UserResponse(**user),
    )


@router.get("/me", response_model=UserResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    return current_user


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    user = await get_user_by_email(request.email)
    if not user:
        return {"message": "Jika email terdaftar, link reset akan dikirim"}
    return {"message": "Fitur reset password belum diimplementasi"}
