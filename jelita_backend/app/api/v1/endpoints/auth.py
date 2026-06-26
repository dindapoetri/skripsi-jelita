from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, EmailStr
from dotenv import load_dotenv

from app.schemas.auth_schema import UserRegister, UserLogin, TokenResponse, UserResponse
from app.services.user_service import create_user, authenticate_user, get_user_by_email
from app.core.security import create_access_token, get_current_user
from app.schemas.auth_schema import ChangePasswordRequest
from app.core.security import verify_password, hash_password
from app.services.user_service import update_user_password

load_dotenv()

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister):
    user = await create_user(data)
    token = create_access_token({"sub": str(user["id"])})
    return TokenResponse(
        access_token=token,
        user=UserResponse(
            id=user["id"],
            full_name=user["full_name"],
            email=user["email"],
            is_active=user["is_active"],
            created_at=user.get("created_at")
        )
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: UserLogin):
    user = await authenticate_user(data.email, data.password)
    token = create_access_token({"sub": str(user["id"])})
    return TokenResponse(
        access_token=token,
        user=UserResponse(
            id=user["id"],
            full_name=user["full_name"],
            email=user["email"],
            is_active=user["is_active"],
            created_at=user.get("created_at")
        ),
    )


@router.get("/me", response_model=UserResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    return current_user


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


# @router.post("/forgot-password")
# async def forgot_password(request: ForgotPasswordRequest):
#     user = await get_user_by_email(request.email)
#     if not user:
#         return {"message": "Jika email terdaftar, link reset akan dikirim"}
#     return {"message": "Fitur reset password belum diimplementasi"}

@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
):
    if not verify_password(
        request.current_password,
        current_user["hashed_password"],
    ):
        return {
            "success": False,
            "message": "Password lama salah",
        }

    new_hash = hash_password(request.new_password)

    await update_user_password(
        current_user["id"],
        new_hash,
    )

    return {
        "success": True,
        "message": "Password berhasil diubah",
    }
