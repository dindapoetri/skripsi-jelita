# Jelita Backend — FastAPI

Backend API untuk aplikasi rekomendasi skincare **Jelita**.  
Stack: **FastAPI + PostgreSQL (asyncpg) + PyTorch CNN + scikit-learn CBF**

---

## 📁 Struktur Proyek

```
jelita_backend/
├── app/
│   ├── api/v1/endpoints/
│   │   ├── auth.py           # Register, Login, Profil
│   │   ├── classify.py       # Upload foto → CNN → simpan riwayat
│   │   ├── recommendations.py# CBF recommendation
│   │   └── history.py        # Riwayat scan user
│   ├── core/
│   │   ├── config.py         # Konfigurasi dari .env
│   │   └── security.py       # JWT, hash password
│   ├── db/
│   │   └── database.py       # Koneksi async PostgreSQL
│   ├── models/               # SQLAlchemy ORM models
│   ├── schemas/              # Pydantic request/response
│   ├── services/
│   │   ├── cbf_service.py    # Logic CBF + TF-IDF
│   │   ├── cnn_service.py    # Inference MobileNetV3
│   │   ├── user_service.py
│   │   └── history_service.py
│   ├── utils/
│   │   └── file_utils.py     # Upload & validasi foto
│   └── main.py               # Entry point FastAPI
├── database/
│   └── setup.sql             # Script buat tabel manual
├── ml_models/                # Taruh file .pkl dan .ptl di sini
├── uploads/photos/           # Foto yang di-upload otomatis tersimpan di sini
├── .env.example
├── requirements.txt
└── run.sh
```

---

## ⚙️ Setup Langkah demi Langkah

### 1. Clone / Salin folder ini ke komputermu

```bash
cd jelita_backend
```

### 2. Buat virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Siapkan database PostgreSQL

Pastikan PostgreSQL sudah berjalan di komputermu, lalu:

```bash
# Masuk ke psql
psql -U postgres

# Buat database
CREATE DATABASE jelita;
\q
```

Kemudian jalankan script SQL:

```bash
psql -U postgres -d jelita -f database/setup.sql
```

### 5. Konfigurasi .env

```bash
cp .env.example .env
```

Edit file `.env`:

```env
DATABASE_URL=postgresql+asyncpg://postgres:PASSWORD_KAMU@localhost:5432/jelita
SECRET_KEY=buat_random_string_panjang_di_sini
```

> Untuk generate SECRET_KEY:
> ```bash
> python -c "import secrets; print(secrets.token_hex(32))"
> ```

### 6. Taruh file model ML

Salin file modelmu ke folder `ml_models/`:

```
ml_models/
├── mobilenetv3_skintype_90.ptl   ← model CNN dari Flutter project
├── cbf_model.pkl                 ← model CBF (jika ada)
└── tfidf_vectorizer.pkl          ← vectorizer TF-IDF (jika ada)
```

> **Catatan:** Jika file `cbf_model.pkl` / `tfidf_vectorizer.pkl` belum ada,
> backend akan otomatis membuat TF-IDF vectorizer baru dari data produk di DB.
> Ini sudah cukup untuk skripsi.

### 7. Jalankan server

```bash
# Windows
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Mac/Linux
bash run.sh
```

Server berjalan di: `http://localhost:8000`  
Swagger docs: `http://localhost:8000/docs`

---

## 📱 Integrasi Flutter

Di Flutter, ubah base URL ke:

```dart
// Untuk emulator Android
const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Untuk device fisik (ganti dengan IP komputermu)
const String baseUrl = 'http://192.168.1.x:8000/api/v1';
```

### Contoh pemanggilan dari Flutter (classify):

```dart
Future<Map<String, dynamic>> classifyAndRecommend({
  required File imageFile,
  required List<String> concerns,
}) async {
  final uri = Uri.parse('$baseUrl/classify/');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path))
    ..fields['concerns'] = jsonEncode(concerns);

  final response = await request.send();
  final body = await response.stream.bytesToString();
  return jsonDecode(body);
}
```

### Contoh pemanggilan rekomendasi:

```dart
Future<Map<String, dynamic>> getRecommendations({
  required String skinType,
  required List<String> concerns,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/recommendations/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'skin_type': skinType,
      'concerns': concerns,
      'top_n': 5,
    }),
  );
  return jsonDecode(response.body);
}
```

---

## 🔗 Endpoint Summary

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/api/v1/auth/register` | ❌ | Daftar akun baru |
| POST | `/api/v1/auth/login` | ❌ | Login, dapat JWT token |
| GET | `/api/v1/auth/me` | ✅ | Profil user aktif |
| POST | `/api/v1/classify/` | ✅ | Upload foto → CNN → simpan riwayat |
| POST | `/api/v1/classify/guest` | ❌ | Klasifikasi tanpa login |
| POST | `/api/v1/recommendations/` | ✅ | Rekomendasi CBF |
| POST | `/api/v1/recommendations/guest` | ❌ | Rekomendasi tanpa login |
| GET | `/api/v1/history/` | ✅ | Daftar riwayat scan |
| GET | `/api/v1/history/{id}` | ✅ | Detail riwayat |
| DELETE | `/api/v1/history/{id}` | ✅ | Hapus riwayat |

---

## ❓ Troubleshooting

**`asyncpg.InvalidPasswordError`**  
→ Password PostgreSQL di `.env` salah

**`relation "users" does not exist`**  
→ Jalankan ulang `database/setup.sql`

**`FileNotFoundError: ml_models/...`**  
→ Salin file model ke folder `ml_models/`. Backend akan tetap jalan dengan model default.

**Flutter tidak bisa connect ke backend**  
→ Pastikan menggunakan `10.0.2.2:8000` untuk emulator, atau IP LAN untuk device fisik
