from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class HistoryScan(Base):
    __tablename__ = "history_scans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Hasil CNN
    skin_type = Column(String(50), nullable=False)   # normal | oily | dry | combination | sensitive
    cnn_confidence = Column(Float)                   # confidence score 0-1

    # Keluhan user (dari input form)
    concerns = Column(JSON)                          # ["jerawat", "minyak berlebih", ...]

    # Foto
    image_url = Column(String(500))                  # path relatif atau URL

    # Rekomendasi yang disimpan (snapshot)
    recommendations_snapshot = Column(JSON)          # [{id, name, brand, category, score}, ...]

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relasi
    user = relationship("User", back_populates="history_scans")
