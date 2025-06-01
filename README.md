# 📅 EduTime – Aplikasi Manajemen Jadwal Perkuliahan

**EduTime** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu mahasiswa mengelola **jadwal kuliah**, **kegiatan kelompok**, dan **aktivitas harian** secara efisien. Aplikasi ini menyatukan manajemen waktu dan kolaborasi dalam satu platform.

---

## 👥 Anggota Kelompok 9RB

| No | Nama                    | NIM       |
|----|-------------------------|-----------|
| 1  | Alfonso Pangaribuan     | 122140206 |
| 2  | Anjes Bermana           | 122140190 |
| 3  | Jhoel Robert Hutagalung | 122140174 |

---

## ✨ Fitur Utama

### 1. Manajemen Jadwal Perkuliahan
- Tambah, edit, dan hapus mata kuliah
- Tampilan jadwal harian & mingguan
- Info lengkap: mata kuliah, ruangan, dosen, waktu

### 2. Manajemen Kerja Kelompok
- Buat jadwal kerja kelompok
- Atur peran dan anggota
- Optimasi waktu terbaik untuk semua

### 3. Dashboard Informatif
- Tampilkan jadwal hari ini
- Pengingat aktivitas mendatang
- Statistik kehadiran & kegiatan

### 4. Fitur Pengguna
- Autentikasi dengan Firebase
- Profil pengguna dapat disesuaikan
- Pengaturan notifikasi dan preferensi

### 5. Fitur Tambahan
- Kalender akademik
- Statistik perkuliahan
- FAQ dan pusat bantuan

---

## 🧰 Teknologi yang Digunakan

- **Flutter** – Framework UI cross-platform  
- **Firebase** – Autentikasi, penyimpanan data, dan analitik  
- **SQLite** – Database lokal  
- **Go Router** – Navigasi dinamis  
- **Material Design** – UI modern dan konsisten  

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                      # Entry point aplikasi
├── firebase_options.dart          # Konfigurasi Firebase
├── models/
│   └── user_profile.dart          # Model pengguna
├── routes/
│   └── app_router.dart            # Navigasi aplikasi
├── screens/
│   ├── about_screen.dart          # Tentang aplikasi
│   ├── homepage.dart              # Halaman utama
│   ├── jadwal_perkuliahan.dart    # Jadwal kuliah
│   ├── jadwal_kerja_kelompok.dart # Jadwal kelompok
│   ├── login/
│   │   ├── auth_screen.dart       # Login/Register
│   │   ├── splash_screen.dart     # Splash screen
│   │   └── welcome_screen.dart    # Halaman awal
│   └── settings.dart              # Pengaturan aplikasi
├── utils/
│   ├── app_theme.dart             # Tema UI
│   └── database_helper.dart       # SQLite helper
└── widgets/
    └── main_scaffold.dart         # Scaffold utama
```

---

## ⚙️ Instalasi & Penggunaan

### Prasyarat
- Flutter SDK (versi terbaru)
- Android Studio atau VS Code
- Firebase CLI

### Langkah Instalasi

```bash
# 1. Clone repositori
git clone https://github.com/yourusername/EduTime.git

# 2. Masuk ke direktori proyek
cd EduTime

# 3. Install dependensi
flutter pub get

# 4. Konfigurasi Firebase
flutterfire configure

# 5. Jalankan aplikasi
flutter run
```

---

## 🗺️ Roadmap Pengembangan

- [ ] Integrasi kalender akademik universitas  
- [ ] Fitur berbagi jadwal dengan teman  
- [ ] Notifikasi pengingat berbasis lokasi  
- [ ] Sinkronisasi dengan Google Calendar  
- [ ] Rekomendasi waktu belajar optimal  

---

## 🤝 Kontribusi

Kami terbuka untuk kontribusi!  
Silakan lakukan fork, buat branch baru, dan ajukan pull request dengan penjelasan perubahan.

```bash
# Clone repo
git clone https://github.com/yourusername/EduTime.git

# Buat branch baru
git checkout -b fitur-baru

# Setelah edit, commit dan push
git commit -m "Tambah fitur X"
git push origin fitur-baru
```

---

## 📝 Lisensi

Lisensi: **[Tentukan lisensi Anda, misal MIT, Apache 2.0]**

---

## 📬 Kontak

Bisa menghubungi antara anggota kelompok diatas.

---
