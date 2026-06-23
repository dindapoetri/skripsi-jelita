# from fastapi import HTTPException, status
# from app.core.security import hash_password, verify_password
# from app.core.supabase import supabase

# async def get_user_by_email(email: str):
#     res = supabase.table("users") \
#         .select("*") \
#         .eq("email", email) \
#         .maybe_single() \
#         .execute()

#     return res.data

# async def get_user_by_id(user_id: str):
#     res = supabase.table("users") \
#         .select("*") \
#         .eq("id", user_id) \
#         .maybe_single() \
#         .execute()

#     return res.data


# async def create_user(data):
#     existing = await get_user_by_email(data.email)

#     if existing:
#         raise HTTPException(
#             status_code=400,
#             detail="Email sudah terdaftar"
#         )

#     res = supabase.table("users").insert({
#         "full_name": data.full_name,
#         "email": data.email,
#         "hashed_password": hash_password(data.password),
#         "is_active": True
#     }).execute()

#     if not res.data:
#         raise HTTPException(500, "Gagal membuat user")

#     return res.data[0]


# async def authenticate_user(email: str, password: str):
#     user = await get_user_by_email(email)

#     if not user:
#         raise HTTPException(401, "Email tidak ditemukan")

#     if not verify_password(password, user["hashed_password"]):
#         raise HTTPException(401, "Password salah")

#     return user