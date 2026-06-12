# JANGAN LUPA BUAT MASUK KE DALEM FILE .ENV DULU
if [ ! -f ".env" ]; then
    echo "ERROR: File .env tidak ditemukan!"
    echo "Salin .env.example menjadi .env dan isi konfigurasinya."
    exit 1
fi

echo "Starting Jelita Backend..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Masuk ke link