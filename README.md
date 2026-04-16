# LecturerDigest 

LecturerDigest adalah aplikasi Flutter cerdas yang membantu mahasiswa merangkum materi kuliah secara otomatis menggunakan AI. Aplikasi ini dapat merekam audio kuliah, membuat transkrip, menghasilkan ringkasan, kartu hafalan (flashcards), dan kuis evaluasi secara instan.

##  Panduan Memulai (Setup)

Ikuti langkah-langkah di bawah ini untuk menjalankan proyek ini di mesin lokal Anda.

### 1. Prasyarat
Pastikan Anda sudah menginstal alat-alat berikut:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versi terbaru direkomendasikan)
- [Dart SDK](https://dart.dev/get-started/sdk)
- Emulator Android/iOS atau perangkat fisik yang terhubung.
- Akun [Supabase](https://supabase.com/) (Gratis).

### 2. Kloning Repositori
```bash
git clone https://github.com/alfanafandi/LecturerDigest.git
cd LecturerDigest
```

### 3. Instalasi Dependensi
Jalankan perintah berikut untuk mengunduh semua paket Flutter yang diperlukan:
```bash
flutter pub get
```

### 4. Konfigurasi Database (Supabase)
Proyek ini menggunakan Supabase sebagai backend. Anda perlu menyiapkan tabel-tabelnya terlebih dahulu:

1.  Buat proyek baru di [Dashboard Supabase](https://supabase.com/dashboard).
2.  Buka menu **SQL Editor**.
3.  Salin isi dari file `database_schema.sql` (ada di root folder proyek ini) dan jalankan di SQL Editor Supabase.
4.  Pastikan semua tabel (`courses`, `lectures`, `summaries`, `flashcards`, `quizzes`, `quiz_attempts`) berhasil dibuat.

### 5. Konfigurasi Environment Variables
Kami menggunakan file `.env` untuk menyimpan kunci API yang sensitif.
1.  Buat file baru bernama `.env` di root folder proyek (atau salin dari `.env.example`).
2.  Isi kunci API Anda dari Dashboard Supabase (**Settings > API**):
    ```env
    SUPABASE_URL=https://your-project-id.supabase.co
    SUPABASE_ANON_KEY=your-anon-key-here
    ```

### 6. Menjalankan Aplikasi
Setelah semuanya siap, Anda bisa menjalankan aplikasi dengan perintah:
```bash
flutter run
```

---

## Fitur Utama
- **Record & AI Synthesis**: Rekam materi dan biarkan AI merangkumnya.
- **Flashcards & Quizzes**: Belajar lebih efektif dengan kartu hafalan dan kuis otomatis.
- **Chat with AI**: Tanya jawab langsung dengan asisten AI terkait materi kuliah.
- **Progress Tracker**: Pantau nilai kuis dan penguasaan materi di dashboard.

---
Disusun oleh Tim LecturerDigest. Selamat belajar!
