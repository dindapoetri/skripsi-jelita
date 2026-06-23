# SEKARANG OTOMATIS NGAMBIL DARI SUPABASE

# from sqlalchemy import Column, Integer, String, Text, Float, ARRAY
# from app.db.database import Base


# class Product(Base):
#     __tablename__ = "products"

#     id = Column(Integer, primary_key=True, index=True)
#     name = Column(String(255), nullable=False, index=True)
#     brand = Column(String(150))
#     category = Column(String(50), index=True)   # facial_wash | toner | moisturizer | sunscreen
#     description = Column(Text)
#     description_clean = Column(Text)
#     how_to_use = Column(Text)
#     suitable_for = Column(Text)
#     ingredients = Column(Text)
#     image_url = Column(String(500))

#     # Kolom CBF — disimpan sebagai string CSV atau JSON, di-parse saat inference
#     cbf_features = Column(Text)
