from fastapi import HTTPException, status
from passlib.context import CryptContext
# from streamlit import user
from supabase import create_client
from dotenv import load_dotenv
import os
from uuid import UUID

load_dotenv()

# ── Supabase client ──
supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

# ── Password hashing ──
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ── User CRUD via Supabase ──

async def get_user_by_email(email: str) -> dict | None:
    try:
        res = supabase.table("users")\
            .select("*")\
            .eq("email", email)\
            .limit(1)\
            .execute()
        return res.data[0] if res.data else None
    except Exception:
        return None


async def get_user_by_id(user_id: UUID) -> dict | None:
    try:
        res = supabase.table("users")\
            .select("*")\
            .eq("id", user_id)\
            .limit(1)\
            .execute()
        return res.data[0] if res.data else None
    except Exception:
        return None


async def create_user(data) -> dict:
    existing = await get_user_by_email(data.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email sudah terdaftar",
        )

    try:
        res = supabase.table("users").insert({
            "full_name": data.full_name,
            "email": data.email,
            "hashed_password": hash_password(data.password),
            "is_active": True,
        }).execute()

        if not res.data:
            raise HTTPException(status_code=500, detail="Gagal membuat akun")

        user = res.data[0]

        return {
            "id": str(user["id"]),
            "full_name": user["full_name"],
            "email": user["email"],
            "is_active": user.get("is_active", True),
            "created_at": user.get("created_at")
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error membuat akun: {str(e)}"
        )


async def authenticate_user(email: str, password: str) -> dict:
    user = await get_user_by_email(email)

    if not user or not verify_password(password, user.get("hashed_password", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau password salah",
        )

    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun tidak aktif",
        )

    return user

# CHANGE PASSWORD
async def update_user_password(user_id, hashed_password):
    response = (
        supabase.table("users")
        .update({"hashed_password": hashed_password})
        .eq("id", str(user_id))
        .execute()
    )

    return response.data