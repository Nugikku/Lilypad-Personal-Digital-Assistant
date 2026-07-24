<div align="center">

# 🪷 Lilypad
### Asisten Digital Pribadi | Personal Digital Assistant

*Teman produktivitas all-in-one — dibangun dengan Flutter & didukung oleh Supabase*
*Your all-in-one productivity companion — built with Flutter & powered by Supabase*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

</div>

---

## 🇮🇩 Bahasa Indonesia

### 📖 Tentang Aplikasi

**Lilypad** adalah aplikasi mobile asisten digital pribadi yang dibangun menggunakan Flutter. Aplikasi ini membantu pengguna mengelola kehidupan sehari-hari melalui sekumpulan fitur terintegrasi — mulai dari pencatatan keuangan pribadi, manajemen kalender, pemantauan cuaca, hingga percakapan dengan asisten AI — semuanya dalam satu aplikasi yang dirancang dengan indah menggunakan estetika pixel-art yang unik.

### ✨ Fitur

| Fitur | Deskripsi |
|-------|-----------|
| 🏠 **Dashboard** | Ringkasan cuaca hari ini dan akses cepat ke semua fitur |
| 📅 **Kalender** | Terintegrasi dengan **Google Calendar API** untuk menampilkan dan mengelola acara |
| 💰 **Pencatat Keuangan** | Lacak pemasukan dan pengeluaran dengan grafik visual |
| 📝 **Catatan** | Buat dan kelola catatan pribadi |
| 🤖 **Lily AI** | Asisten AI bawaan yang didukung oleh Google Gemini |
| 🌤️ **Cuaca** | Data cuaca real-time menggunakan **Open-Meteo API** |
| 👤 **Profil** | Manajemen profil pengguna |

### 🛠️ Teknologi yang Digunakan

**Frontend**
- **Flutter** — Framework mobile lintas platform
- **Dart** — Bahasa pemrograman
- **Google Fonts** — Tipografi (`Plus Jakarta Sans`)
- **FL Chart** — Visualisasi data untuk grafik keuangan

**Backend & Layanan**
- **Supabase** — Backend-as-a-Service
  - Database PostgreSQL
  - Autentikasi (Email/Password & Google Sign-In)
  - Row Level Security (RLS) untuk keamanan data
- **Google Calendar API** — Sinkronisasi acara kalender
- **Open-Meteo API** — Data cuaca gratis & open-source (tidak membutuhkan API key)
- **Google Gemini** — Asisten chat AI

### 🏗️ Struktur Proyek

```
lilypad_app/
├── lib/
│   ├── main.dart              # Entry point aplikasi & inisialisasi Supabase
│   ├── screens/               # Semua halaman UI
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── weather_screen.dart
│   │   ├── finance_screen.dart
│   │   ├── notes_screen.dart
│   │   ├── lily_chat_screen.dart
│   │   └── profile_screen.dart
│   ├── theme/                 # Tema & warna aplikasi
│   └── widgets/               # Komponen UI yang dapat digunakan ulang
├── android/                   # Konfigurasi khusus Android
└── .env                       # 🔒 API key rahasia (tidak dilacak oleh Git)
```

### 🔒 Keamanan

- Semua API key rahasia disimpan di file `.env` dan **dikecualikan dari version control** melalui `.gitignore`
- Database dilindungi oleh **Row Level Security (RLS)** — pengguna hanya bisa mengakses data miliknya sendiri
- Google OAuth 2.0 digunakan untuk Google Sign-In yang aman

### 🌐 REST API (Supabase PostgREST)

Aplikasi ini menggunakan **Supabase** yang secara otomatis membuatkan endpoint REST API untuk setiap tabel di database. 

**🔗 Base URL:**
```
https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/
```

Berikut adalah REST API yang terintegrasi dan digunakan dalam aplikasi ini:

- **Authentication API (Supabase Auth)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/auth/v1/`
  - Deskripsi: Endpoint bawaan untuk fitur pendaftaran (Register), masuk (Login), keluar (Sign Out), dan manajemen sesi pengguna.

- **Transactions API (`transactions`)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/transactions`
  - Deskripsi: Endpoint untuk mengelola (GET, POST, DELETE) data riwayat pemasukan dan pengeluaran pada fitur *Finance*.

- **Notes API (`notes`)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/notes`
  - Deskripsi: Endpoint untuk membaca, membuat, memperbarui, dan menghapus catatan (GET, POST, PATCH, DELETE) pada fitur *My Notes*.

- **Schedules API (`schedules`)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/schedules`
  - Deskripsi: Endpoint untuk mengatur jadwal acara di fitur *Calendar* (GET, POST, DELETE).

> [!WARNING]
> **Akses API Ketat & Terbatas**
> Endpoint REST API pada proyek ini **tidak bisa diakses atau ditembak secara bebas dari luar aplikasi** (misalnya menggunakan Postman atau browser tanpa token autentikasi yang sah). Hal ini dikarenakan seluruh tabel database dilindungi dengan sangat ketat menggunakan fitur **Row Level Security (RLS)** bawaan Supabase. Kebijakan RLS memastikan setiap proses permintaan (Request) hanya diizinkan apabila menyertakan token JWT yang valid, dan pengguna dibatasi *hanya* dapat membaca serta memodifikasi data miliknya sendiri (berdasarkan kolom `user_id`).

### ⚡ Cara Memulai

**Prasyarat**
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x atau lebih baru)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)
- Akun [Supabase](https://supabase.com/)
- Project [Google Cloud Console](https://console.cloud.google.com/)

**Instalasi**

1. Clone repositori
```bash
git clone https://github.com/Nugikku/Lilypad-Personal-Digital-Assistant.git
cd Lilypad-Personal-Digital-Assistant
```

2. Install dependensi
```bash
flutter pub get
```

3. Buat file `.env` Anda sendiri di root project:
```env
GOOGLE_CALENDAR_API_KEY=masukkan_api_key_google_calendar_anda
SUPABASE_URL=masukkan_url_project_supabase_anda
SUPABASE_ANON_KEY=masukkan_anon_key_supabase_anda
```

4. Jalankan aplikasi
```bash
flutter run
```

### ⚠️ Keterbatasan

- **Sinkronisasi Google Calendar** — Saat ini hanya baca saja; membuat/mengedit acara melalui aplikasi belum didukung
- **Mode Offline** — Aplikasi membutuhkan koneksi internet aktif untuk sebagian besar fitur
- **Kecepatan Respons AI** — Waktu respons Lily AI bergantung pada kecepatan jaringan dan ketersediaan Gemini API
- **Platform** — Saat ini dioptimalkan untuk Android; dukungan iOS mungkin memerlukan konfigurasi tambahan

---

## 🇬🇧 English

### 📖 About

**Lilypad** is a personal digital assistant mobile application built with Flutter. It helps users manage their daily life through an integrated set of tools — from tracking personal finances, managing a calendar, monitoring the weather, to chatting with an AI assistant — all in one beautifully designed app with a unique pixel-art aesthetic.

### ✨ Features

| Feature | Description |
|---------|-------------|
| 🏠 **Dashboard** | Overview of today's weather, quick access to all features |
| 📅 **Calendar** | Integrated with **Google Calendar API** to display and manage events |
| 💰 **Finance Tracker** | Track income and expenses with visual charts |
| 📝 **Notes** | Create and manage personal notes |
| 🤖 **Lily AI** | Built-in AI assistant powered by Google Gemini |
| 🌤️ **Weather** | Real-time weather data using **Open-Meteo API** |
| 👤 **Profile** | User profile management |

### 🛠️ Tech Stack

**Frontend**
- **Flutter** — Cross-platform mobile framework
- **Dart** — Programming language
- **Google Fonts** — Typography (`Plus Jakarta Sans`)
- **FL Chart** — Data visualization for finance charts

**Backend & Services**
- **Supabase** — Backend-as-a-Service
  - PostgreSQL Database
  - Authentication (Email/Password & Google Sign-In)
  - Row Level Security (RLS) for data protection
- **Google Calendar API** — Calendar event synchronization
- **Open-Meteo API** — Free, open-source weather data (no API key required)
- **Google Gemini** — AI chat assistant

### 🏗️ Architecture

```
lilypad_app/
├── lib/
│   ├── main.dart              # App entry point & Supabase init
│   ├── screens/               # All UI screens
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── weather_screen.dart
│   │   ├── finance_screen.dart
│   │   ├── notes_screen.dart
│   │   ├── lily_chat_screen.dart
│   │   └── profile_screen.dart
│   ├── theme/                 # App theming & colors
│   └── widgets/               # Reusable UI components
├── android/                   # Android-specific config
└── .env                       # 🔒 Secret API keys (not tracked by Git)
```

### 🔒 Security

- All secret API keys are stored in a `.env` file and **excluded from version control** via `.gitignore`
- Database is protected by **Row Level Security (RLS)** — users can only access their own data
- Google OAuth 2.0 is used for secure Google Sign-In

### 🌐 REST API (Supabase PostgREST)

This application utilizes **Supabase**, which automatically generates REST API endpoints for every database table. 

**🔗 Base URL:**
```
https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/
```

The following REST APIs are integrated into this app:

- **Authentication API (Supabase Auth)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/auth/v1/`
  - Description: Built-in endpoints for User Registration, Login, Sign Out, and session management.

- **Transactions API (`transactions`)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/transactions`
  - Description: Endpoints to manage (GET, POST, DELETE) income and expense tracking data in the *Finance* feature.

- **Notes API (`notes`)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/notes`
  - Description: Endpoints for reading, creating, updating, and deleting user notes (GET, POST, PATCH, DELETE) in the *My Notes* feature.

- **Schedules API (`schedules`)**
  - Endpoint: `https://lifbpoeqwghiuoshcoka.supabase.co/rest/v1/schedules`
  - Description: Endpoints for managing events in the *Calendar* feature (GET, POST, DELETE).

> [!WARNING]
> **Strict API Access Control**
> The REST APIs in this project **cannot be accessed arbitrarily from outside the application** (e.g., using Postman or a browser without a valid authentication token). This is because all database tables are strictly protected using Supabase's built-in **Row Level Security (RLS)**. RLS policies guarantee that any database operation is only allowed if the request includes a valid JWT token, and users are strictly limited to reading and modifying only their own data (filtered by the `user_id` column).

### ⚡ Getting Started

**Prerequisites**
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x or later)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- A [Supabase](https://supabase.com/) account
- A [Google Cloud Console](https://console.cloud.google.com/) project

**Installation**

1. Clone the repository
```bash
git clone https://github.com/Nugikku/Lilypad-Personal-Digital-Assistant.git
cd Lilypad-Personal-Digital-Assistant
```

2. Install dependencies
```bash
flutter pub get
```

3. Create your `.env` file in the project root:
```env
GOOGLE_CALENDAR_API_KEY=your_google_calendar_api_key_here
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

4. Run the app
```bash
flutter run
```

### ⚠️ Limitations

- **Google Calendar Sync** — Currently read-only; creating/editing events via the app is not yet supported
- **Offline Mode** — The app requires an active internet connection for most features
- **AI Response Speed** — Lily AI response time depends on network speed and Gemini API availability
- **Platform** — Currently optimized for Android; iOS support may require additional configuration

---

## 📄 License | Lisensi

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Proyek ini dilisensikan di bawah **MIT License** — lihat file [LICENSE](LICENSE) untuk detail lebih lanjut.

---

<div align="center">

Made with ❤️ by **Nugroho Saputra Jati** | Universitas Duta Bangsa Surakarta — Pemrograman Mobile Semester 4 - Angkatan 24

*🪷 Lilypad — Tetap terorganisir, tetap produktif | Stay organized, stay productive*

</div>
