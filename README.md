<div align="center">
  <img src="assets/images/logo-light.png" width="110" alt="Soul Logo">
  <h1>Platform Manajemen Ekstrakurikuler Sekolah</h1>
</div>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.4-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.13.3-0175C2?style=flat-square&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Riverpod-3.4.3-purple?style=flat-square" alt="Riverpod">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-success?style=flat-square" alt="Platforms">
</p>

---

## 📌 Tentang Proyek
**Soul** adalah aplikasi seluler yang dirancang untuk mengoptimalkan pengelolaan kegiatan ekstrakurikuler di lingkungan sekolah. Aplikasi ini mendukung dua peran utama dengan alur kerja spesifik: **Ketua Ekstrakurikuler** dan **Siswa**.

---

## 📂 Struktur Direktori & Dokumentasi Source Code

Seluruh kode sumber berada di dalam folder `lib/` dengan pembagian arsitektur modular berikut:

```text
lib/
├── core/                # Konfigurasi inti, API client, local storage, dan notification service
├── data/                # Definisi Riverpod Async/FutureProvider untuk komunikasi backend
├── models/              # Representasi model data (User, Pendaftaran, Kegiatan, Notifikasi, dll)
├── screens/             # Kumpulan layar aplikasi (Beranda, Anggota, Kegiatan, Presensi, Profil, dll)
│   ├── aktivitas/       # Modul aktivitas dan presensi siswa
│   ├── anggota/         # Modul pengelolaan anggota & pendaftaran (Ketua)
│   ├── beranda/         # Dashboard utama (Ketua & Siswa)
│   ├── katalog/         # Daftar & detail ekstrakurikuler
│   ├── kegiatan/        # Manajemen kegiatan, detail, dan scanner QR presensi
│   ├── laporan/         # Laporan bulanan kegiatan ekskul
│   ├── menu/            # Menu navigasi tambahan ketua
│   ├── nilai/           # Rekap penilaian siswa
│   ├── notifikasi/      # Pusat notifikasi & badge unread
│   └── profil/          # Pengaturan akun, edit profil, dan pengajuan keluar
├── theme/               # Pengaturan tema visual (Light/Dark mode & AppTheme)
└── widgets/             # Komponen UI reusable (Common widgets, PaginatedList, dll)
```

---

## 🛠️ Ringkasan Fitur & Peran Pengguna

### 1. Peran Siswa (`SiswaShell`)
- **Beranda Siswa**: Menampilkan ringkasan status keanggotaan ekskul, persentase kehadiran, agenda kegiatan mendatang, tren kehadiran, serta menu akses cepat.
- **Katalog Ekskul**: Menjelajahi daftar ekstrakurikuler yang tersedia dan melakukan pendaftaran.
- **Aktivitas & Presensi**: Memantau riwayat kehadiran, rekap per bulan, nilai periodik, serta melakukan presensi mandiri.
- **Pengajuan Keluar**: Formulir pengajuan pengunduran diri dari ekstrakurikuler dengan alasan.

### 2. Peran Ketua (`KetuaShell`)
- **Dashboard Ketua**: Statistik anggota aktif, antrian pendaftaran baru, grafik kehadiran, serta ringkasan moderasi (testimoni & FAQ).
- **Pengelolaan Anggota**: Tab terpadu (*Anggota*, *Pendaftaran*, *Pengajuan*) dengan sistem filter ganda (status & waktu), pencarian nama, serta aksi ubah status (aktif, peringatan, nonaktif, keluar).
- **Manajemen Kegiatan**: Membuat kegiatan rutin/event baru, melihat rekap presensi, serta melakukan **Presensi QR** (via *built-in camera scanner* atau *decode* langsung dari galeri foto).
- **Laporan & Moderasi**: Mengelola laporan bulanan, moderasi testimoni, dan FAQ.

---

## 🚀 Cara Menjalankan Aplikasi

Aplikasi Soul membutuhkan konfigurasi environment `API_BASE_URL` saat dijalankan menggunakan `--dart-define`.

1. **Pastikan Flutter SDK terpasang** (Versi 3.47.4 atau yang direkomendasikan).
2. **Kloning atau buka direktori proyek** di terminal.
   ```bash
   git clone https://github.com/Haruzenn69/Soul-Mobile.git
   cd Soul-Mobile
   ```
3. **Instal dependensi**:
   ```bash
   flutter pub get
   ```
4. **Jalankan aplikasi dengan Dart Define**:
   ```bash
   flutter run --dart-define=API_BASE_URL=https://your-api-domain.com
   ```
   *(Ganti URL di atas dengan endpoint backend REST API yang sesuai).*

---

## 🔍 Standar & Konvensi Kode
- **Dokumentasi**: Menggunakan kombinasi DartDoc (`///`) untuk dokumentasi class/method dan inline comment (`//`) untuk penjelasan blok logika kompleks.
- **State Management**: Menggunakan `Flutter Riverpod` untuk reaktifitas data yang bersih dan teruji.
- **UI/UX**: Mengikuti panduan Material Design dengan kustomisasi font *Plus JakartaSans* dan tema warna dinamis.
