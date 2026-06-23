from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List
import os
from pathlib import Path
from typing import ClassVar

# BASE_DIR = Path(__file__).resolve().parent.parent.parent
class Settings(BaseSettings):
    
    BASE_DIR: ClassVar[Path] = Path(__file__).resolve().parents[2]
    
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_SERVICE_ROLE_KEY: str
    
    # App
    APP_NAME: str = "Jelita Skincare API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True

    # Database Postgresql #
    DATABASE_URL: str = "postgresql+asyncpg://postgres:dinda130714@localhost:5432/jelita"

    # JWT
    SECRET_KEY: str = "68ed4a282d1792a6b5d1332f6cdc918bc1c9143c15bd3ad5e4345cd51a571b08"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 86400  # 2 bulan

    # Upload
    UPLOAD_DIR: str = "uploads/photos"
    MAX_FILE_SIZE_MB: int = 5

    # ML Models
    CBF_MODEL_PATH: str = "jelita_backend\\assets\\models\\cbf\\cbf_model_22june.jotlib"
    CNN_MODEL_PATH: str = str(BASE_DIR / "assets/models/cnn/mobilenetv3_skintype_90.ptl")
    
    # SMTP (Reset Password Email)
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""  # gunakan App Password Gmail, bukan password akun biasa
    SMTP_FROM_EMAIL: str = ""
    SMTP_FROM_NAME: str = "Jelita Skincare"
    RESET_TOKEN_EXPIRE_MINUTES: int = 60

    # CORS
    ALLOWED_ORIGINS: str = "http://localhost,http://10.0.2.2"

    @property
    def allowed_origins_list(self) -> List[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",")]

    @property
    def max_file_size_bytes(self) -> int:
        return self.MAX_FILE_SIZE_MB * 1024 * 1024

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()

# Membuat direktori baru
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
os.makedirs("ml_models", exist_ok=True)
