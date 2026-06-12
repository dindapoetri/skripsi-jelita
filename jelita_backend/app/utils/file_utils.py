import uuid
import os
from fastapi import HTTPException, UploadFile
from app.core.config import settings

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}


async def save_upload_photo(file: UploadFile, subfolder: str = "") -> str:
    """
    Simpan foto ke disk, return path relatif.
    Contoh return: "uploads/photos/2024/abc123.jpg"
    """
    # Validasi tipe file
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Tipe file tidak didukung: {file.content_type}. "
                   f"Gunakan JPEG, PNG, atau WebP.",
        )

    # Baca dan validasi ukuran
    contents = await file.read()
    if len(contents) > settings.max_file_size_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"Ukuran file terlalu besar. Maksimal {settings.MAX_FILE_SIZE_MB}MB.",
        )

    # Tentukan ekstensi
    ext_map = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
        "image/heic": ".heic",
    }
    ext = ext_map.get(file.content_type, ".jpg")

    # Buat nama file unik
    filename = f"{uuid.uuid4().hex}{ext}"
    save_dir = os.path.join(settings.UPLOAD_DIR, subfolder)
    os.makedirs(save_dir, exist_ok=True)

    filepath = os.path.join(save_dir, filename)
    with open(filepath, "wb") as f:
        f.write(contents)

    return filepath, contents   # return path dan bytes untuk CNN inference
