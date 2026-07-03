from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime
from uuid import UUID

class UserRegister(BaseModel):
    full_name: str
    username: str
    email: EmailStr
    password: str

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v):
        if len(v) < 6:
            raise ValueError("Password minimal 6 karakter")
        return v

    @field_validator("full_name")
    @classmethod
    def name_not_empty(cls, v):
        if not v.strip():
            raise ValueError("Nama tidak boleh kosong")
        return v.strip()

    @field_validator("username")
    @classmethod
    def username_valid(cls, v):
        v = v.strip()
        if not v:
            raise ValueError("Username tidak boleh kosong")
        if len(v) < 3:
            raise ValueError("Username minimal 3 karakter")
        if " " in v:
            raise ValueError("Username tidak boleh mengandung spasi")
        return v.lower()

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: UUID
    full_name: str
    username: Optional[str] = None
    email: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
    
class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=6)
    new_password: str = Field(..., min_length=6)
    
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class TokenData(BaseModel):
    user_id: Optional[UUID] = None