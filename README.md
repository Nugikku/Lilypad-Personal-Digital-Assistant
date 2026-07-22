<div align="center">

# 🪷 Lilypad
### Personal Digital Assistant

*Your all-in-one productivity companion — built with Flutter & powered by Supabase*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

</div>

---

## 📖 About

**Lilypad** is a personal digital assistant mobile application built with Flutter. It helps users manage their daily life through an integrated set of tools — from tracking personal finances, managing a calendar, monitoring the weather, to chatting with an AI assistant — all in one beautifully designed app with a unique pixel-art aesthetic.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🏠 **Dashboard** | Overview of today's weather, quick access to all features |
| 📅 **Calendar** | Integrated with **Google Calendar API** to display and manage events |
| 💰 **Finance Tracker** | Track income and expenses with visual charts |
| 📝 **Notes** | Create and manage personal notes |
| 🤖 **Lily AI** | Built-in AI assistant powered by Google Gemini |
| 🌤️ **Weather** | Real-time weather data using **Open-Meteo API** |
| 👤 **Profile** | User profile management |

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** — Cross-platform mobile framework
- **Dart** — Programming language
- **Google Fonts** — Typography (`Plus Jakarta Sans`)
- **FL Chart** — Data visualization for finance charts

### Backend & Services
- **Supabase** — Backend-as-a-Service
  - PostgreSQL Database
  - Authentication (Email/Password & Google Sign-In)
  - Row Level Security (RLS) for data protection
- **Google Calendar API** — Calendar event synchronization
- **Open-Meteo API** — Free, open-source weather data (no API key required)
- **Google Gemini** — AI chat assistant

---

## 🏗️ Architecture

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

---

## 🔒 Security

- All secret API keys are stored in a `.env` file and **excluded from version control** via `.gitignore`
- Database is protected by **Row Level Security (RLS)** — users can only access their own data
- Google OAuth 2.0 is used for secure Google Sign-In

---

## ⚡ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x or later)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- A [Supabase](https://supabase.com/) account
- A [Google Cloud Console](https://console.cloud.google.com/) project

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/Nugikku/Lilypad-Personal-Digital-Assistant.git
cd Lilypad-Personal-Digital-Assistant
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Create your `.env` file**

Create a `.env` file in the project root and fill in your own keys:
```env
GOOGLE_CALENDAR_API_KEY=your_google_calendar_api_key_here
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

**4. Run the app**
```bash
flutter run
```

---

## ⚠️ Limitations

- **Google Calendar Sync** — Currently read-only; creating/editing events via the app is not yet supported
- **Offline Mode** — The app requires an active internet connection for most features
- **AI Response Speed** — Lily AI response time depends on network speed and Gemini API availability
- **Platform** — Currently optimized for Android; iOS support may require additional configuration

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ by **Nugikku** | Universitas — Pemrograman Mobile Semester 4

*🪷 Lilypad — Stay organized, stay productive*

</div>
