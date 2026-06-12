-- ============================================================
--  JELITA - Setup Database PostgreSQL
--  Jalankan script ini di psql atau pgAdmin
-- ============================================================

-- 1. Buat database (jalankan sebagai superuser di luar database jelita)
-- CREATE DATABASE jelita;

-- 2. Sambungkan ke database jelita, lalu jalankan sisanya
-- \c jelita

-- ─── Tabel users ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ
);

-- ─── Tabel products ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    brand               VARCHAR(150),
    category            VARCHAR(50),          -- facial_wash | toner | moisturizer | sunscreen
    description         TEXT,                 -- deskripsi mentah dari scraping
    description_clean   TEXT,                 -- deskripsi sudah dibersihkan
    how_to_use          TEXT,                 -- hasil parsing dari deskripsi
    suitable_for        TEXT,                 -- hasil parsing dari deskripsi
    ingredients         TEXT,
    image_url           VARCHAR(500),
    cbf_features        TEXT                  -- fitur gabungan untuk TF-IDF
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);

-- ─── Tabel history_scans ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS history_scans (
    id                      SERIAL PRIMARY KEY,
    user_id                 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skin_type               VARCHAR(50) NOT NULL,
    cnn_confidence          FLOAT,
    concerns                JSONB,            -- ["jerawat", "minyak berlebih"]
    image_url               VARCHAR(500),
    recommendations_snapshot JSONB,           -- snapshot produk rekomendasi saat itu
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_history_user_id ON history_scans(user_id);
CREATE INDEX IF NOT EXISTS idx_history_created ON history_scans(created_at DESC);

-- ─── Verifikasi ──────────────────────────────────────────────
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
