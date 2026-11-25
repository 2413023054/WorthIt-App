# WorthIt - Smart Purchase Feasibility & Price Comparison 📱

Aplikasi Android berbasis Flutter dengan database cloud gratis Supabase yang dirancang untuk membantu mahasiswa, pelajar, dan masyarakat umum mengambil keputusan belanja yang bijak, rasional, dan hemat melalui analisis kelayakan pembelian serta perbandingan harga satuan produk secara akurat.

---

## 🌟 Fitur Utama

1. **Analisis Kelayakan Pembelian (Smart Purchase Feasibility)**
   - Input nama barang, harga, dan anggaran belanja pengguna.
   - Pilihan tingkat kebutuhan (*Primer/Mendesak*, *Sekunder/Penting*, *Tersier/Keinginan*).
   - Pilihan frekuensi pemakaian (*Setiap Hari*, *Beberapa Kali Seminggu*, *Jarang*).
   - Analisis otomatis menghasilkan rekomendasi:
     - 🟢 **Worth It** (Sangat layak dibeli).
     - 🟡 **Consider** (Perlu dipertimbangkan kembali).
     - 🔴 **Not Worth It** (Sebaiknya ditunda).
   - Disertai kalkulasi persentase rasio anggaran dan paragraf alasan logis.

2. **Perbandingan Harga Cerdas (Smart Price Comparison)**
   - Mendukung perbandingan 2 hingga 4 produk sekaligus.
   - Mendukung 3 kategori satuan dengan normalisasi otomatis:
     - **Berat**: Gram (g), Kilogram (kg), Miligram (mg) $\rightarrow$ Normalisasi ke harga per gram / per kg.
     - **Volume**: Mililiter (ml), Liter (l) $\rightarrow$ Normalisasi ke harga per ml / per liter.
     - **Jumlah**: Pcs, Buah, Sachet, Butir, Botol, Lembar $\rightarrow$ Normalisasi ke harga per unit/pcs.
   - Menampilkan mahkota 👑 **"Paling Hemat" (*Best Value*)** pada produk dengan harga satuan terendah.
   - Menghitung persentase penghematan dan selisih nominal.
   - **Smart Budget Alert**: Peringatan otomatis jika produk yang paling hemat memiliki total harga beli di atas anggaran yang dimiliki pengguna.

3. **Riwayat Aktivitas & Penyimpanan Data**
   - Riwayat analisis kelayakan beli dan perbandingan harga tersimpan rapi.
   - Filter tab: *Semua*, *Analisis Beli*, dan *Komparasi*.
   - Kolom pencarian riwayat dan fitur hapus riwayat.
   - Mendukung **Mode Tamu (Guest Mode)**: data disimpan di memori lokal HP (`shared_preferences`).
   - Mendukung **Sinkronisasi Cloud Supabase**: data lokal otomatis dicadangkan ke database PostgreSQL Supabase saat login/daftar akun.

4. **Dashboard & Profil Pengguna**
   - Kartu sambutan dan status pengguna.
   - Tombol pintasan aksi cepat: *Analisis Beli* & *Banding Harga*.
   - Ringkasan statistik aktivitas dan daftar aktivitas terkini.
   - Pengaturan tema: **Dual Theme** (Otomatis Sistem, Mode Terang, Mode Gelap) berpalet **Modern Tech Indigo & Vibrant Cyan**.
   - Sistem login dan pendaftaran akun via Supabase Auth.

---

## 🛠️ Panduan Pengaturan Supabase

Database WorthIt menggunakan **Supabase PostgreSQL** dengan perlindungan penuh **Row Level Security (RLS)**.

### Langkah Setup Supabase:

1. Buat proyek baru di [Supabase Dashboard](https://supabase.com).
2. Buka menu **SQL Editor** pada sidebar Supabase.
3. Buka file `database_schema.sql` di root proyek ini, salin seluruh kodenya, lalu jalankan (*Run*) di Supabase SQL Editor.
   - Skrip ini akan membuat tabel `profiles`, `purchase_analyses`, dan `price_comparisons`, mengaktifkan RLS, serta memasang trigger otomatis untuk pembuatan profil saat pendaftaran akun.
4. Buka menu **Project Settings** > **API** di dashboard Supabase, lalu salin:
   - **Project URL**
   - **anon / public Key** (atau Publishable Key)

---

## 🚀 Cara Menjalankan Aplikasi dengan Supabase

Untuk menjaga keamanan kredensial agar tidak terekspos di repositori Git, aplikasi menggunakan `--dart-define`:

### 1. Menjalankan Aplikasi (Debug/Run):
```bash
flutter run \
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"
```

> **Catatan:** Jika dijalankan tanpa argumen `--dart-define`, aplikasi akan otomatis berjalan dalam **Mode Tamu (Offline Guest Mode)** dengan seluruh fitur tetap aktif menggunakan penyimpanan lokal.

### 2. Menjalankan via VS Code:
Buka file `.vscode/launch.json`, masukkan URL dan Key pada konfigurasi `"WorthIt (Online Supabase)"`, lalu tekan **F5** atau klik **Run & Debug**.

### 3. Menguji Unit Test:
```bash
flutter test
```

---

## 📦 Build APK Android (GitHub Actions & Lokal)

### A. Otomatis via GitHub Actions CI/CD:
1. Masuk ke repositori GitHub Anda $\rightarrow$ **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions**.
2. Tambahkan 2 Repository Secrets:
   - `SUPABASE_URL`: URL proyek Supabase Anda.
   - `SUPABASE_ANON_KEY`: Anon / Publishable Key Anda.
3. Lakukan `git push` ke branch `main`.
4. File APK siap unduh tersedia di tab **Actions** > **Artifacts** dengan nama **WorthIt-Android-Release-APK**.

### B. Manual di Komputer Lokal:
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="YOUR_PUBLISHABLE_OR_ANON_KEY"
```
Hasil file APK berada di:
`build/app/outputs/flutter-apk/app-release.apk`
