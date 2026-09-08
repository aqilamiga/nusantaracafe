# ☕ 1 Nusantara Cafe - Mobile Management App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Figma](https://img.shields.io/badge/Figma-F24E1E?style=for-the-badge&logo=figma&logoColor=white)

**1 Nusantara Cafe** adalah aplikasi manajemen kafe berbasis *multi-role* (Customer, Kasir, Dapur) yang dirancang untuk mempermudah operasional kafe, pengelolaan menu, serta integrasi reservasi acara (*event booking*) secara *real-time*.

---

## 🌟 Fitur Utama

### 👥 1. Role-Based Access Control (RBAC)
* **Customer / Pembeli**: Jelajahi menu, lihat jadwal acara kafe, dan batasan reservasi untuk akun *guest*.
* **Kasir**: Pengelolaan penuh menu (tambah/hapus/status stok), pembuatan *event*, dan manajemen kuota peserta.
* **Dapur**: Tampilan pesanan masuk secara *real-time* untuk mempercepat alur produksi.

### 🔐 2. Username-Based Authentication
* Pendaftaran akun dengan identitas *Username* unik (di-mapping otomatis ke Firebase Auth).
* Kemudahan *login* bagi staf dan pelanggan tanpa perlu mengetik alamat email.

### 📅 3. Event Management & Google Calendar Sync
* Pembuat *event* dengan pemilihan tanggal, jam, dan menit secara presisi.
* Fitur **"Add to Google Calendar"** untuk sinkronisasi otomatis jadwal acara ke kalender pengguna via `url_launcher`.

---

## 🛠️ Teknologi & Tools

* **Frontend Framework**: Flutter (Dart)
* **Backend & Database**: Firebase Authentication & Cloud Firestore
* **Design & Prototyping**: Figma
* **Packages**: `url_launcher`, `firebase_core`, `cloud_firestore`, `firebase_auth`

---

## 📁 Struktur Direktori Utama

```text
lib/
├── models/          # Data model (UserModel, MenuModel, EventModel)
├── pages/
│   ├── auth/        # MainGateway & AuthPage (Login/Register)
│   ├── customer/    # Dashboard & Tampilan Menu/Event Customer
│   ├── kasir/       # Dashboard Pengelolaan Menu & Event Kasir
│   └── dapur/       # Dashboard Monitor Pesanan Dapur
└── services/        # AuthService & DatabaseService (Firebase Firestore)
```
## 🚀 Panduan Instalasi Lokal

Jika Anda ingin menjalankan aplikasi ini di komputer lokal, ikuti langkah-langkah berikut:

### 1. Clone Repository
```bash
git clone [https://github.com/aqilamiga/nusantaracafe.git](https://github.com/aqilamiga/nusantaracafe.git)
cd nusantaracafe
```

### 2. Baca Dokumentasi Proyek
Buka dan baca file README.md ini terlebih dahulu untuk memahami alur struktur proyek, dependency, dan konfigurasi environment sebelum menjalankan aplikasi.

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Konfigurasi Firebase
Pastikan kamu telah mengonfigurasi firebase_options.dart menggunakan Firebase CLI:
```bash
flutterfire configure
```

### 5. Jalankan Aplikasi
```bash
flutter run
```

## 📌 Catatan Keamanan & Git

File lib/firebase_options.dart dan kunci API sensitif telah dikecualikan dari pelacakan Git melalui .gitignore untuk menjaga keamanan kuota dan konfigurasi project.

## 📝 Penulis / Pengembang

[q-l]

Full-Stack Mobile Developer & UI/UX Designer
