# 🎓 PathWise

> **The Education and Career Prediction Application** — Your intelligent companion for educational planning and career exploration.

<div align="center">

![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

[Features](#-features) • [Getting Started](#-getting-started) • [Architecture](#-architecture) • [Tech Stack](#-tech-stack)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [💻 Tech Stack](#-tech-stack)
- [🚀 Getting Started](#-getting-started)
- [📦 Installation](#-installation)
- [🛠️ Development](#️-development)
- [📁 Project Structure](#-project-structure)
- [🔧 Configuration](#-configuration)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## Overview

**PathWise** is a comprehensive Flutter application designed to help students and professionals make informed decisions about their education and career paths. It leverages AI-powered matching, personality assessments, and career analytics to provide personalized recommendations.

Whether you're exploring educational institutions, comparing career paths, or preparing for interviews, PathWise provides intelligent tools to guide your journey.

---

## ✨ Features

### 🎯 Core Features

| Feature | Description |
|---------|-------------|
| **🏫 University Discovery** | Browse and filter 1000+ universities with detailed program information |
| **🔍 Program Comparison** | Compare educational programs side-by-side to find the best fit |
| **🤖 AI Career Matching** | AI-powered career recommendations based on your profile (powered by Google Gemini) |
| **📊 Personality Assessments** | Complete personality evaluations using industry-standard tests |

### 🧠 Personality Tests

- **MBTI (Myers-Briggs)** — 16 personality types aligned with career paths
- **RIASEC** — Holland's theory of career interest assessment
- **Big Five** — Comprehensive personality traits evaluation

### 👤 User Profile Management

- Personal information management
- Skills and expertise tracking
- Education history and credentials
- Work experience documentation
- Career preferences and goals
- Language proficiency levels
- Personality test results

### 💼 Career Tools

| Tool | Description |
|------|-------------|
| **Interview Preparation** | Practice interviews with AI feedback and scoring |
| **Career Roadmap** | Visualize your career progression path |
| **Resume Builder** | Create professional resumes with multiple templates |
| **Job Search** | Discover opportunities matching your profile |

### 🌐 Additional Features

- **Offline Support** — Local SQLite database for continuous access
- **Cloud Sync** — Automatic synchronization with Supabase backend
- **Dark Mode** — Comfortable viewing in any lighting condition
- **Multi-language** — Support for multiple languages
- **Notifications** — Real-time updates and reminders

---

## 🏗️ Architecture

PathWise uses a **three-layer architecture** with intelligent sync capabilities:

```
┌─────────────────────────────────────┐
│         UI Layer (Flutter)          │
│    Screens, Widgets, Views          │
│         (Provider Pattern)          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      ViewModel Layer                │
│   Business Logic & State Management │
│     (ChangeNotifier Providers)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Data Layer                     │
│  ┌────────────────────────────────┐ │
│  │ SQLite (Local Cache)           │ │
│  │ • Universities, Programs       │ │
│  │ • User Preferences, History    │ │
│  └────────────────────────────────┘ │
│  ┌────────────────────────────────┐ │
│  │ Backend Services               │ │
│  │ • Firebase (Auth, Real-time)   │ │
│  │ • Supabase (Sync, CRUD)        │ │
│  │ • Google Gemini (AI Matching)  │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Data Flow

1. **Local First** — App reads from SQLite for instant UX
2. **Background Sync** — Checks backend for updates every 6 hours
3. **Smart Conflict Resolution** — Merges local and cloud changes
4. **Offline Resilience** — Full functionality without internet

---

## 💻 Tech Stack

### 📱 Frontend
- **Flutter** — Cross-platform UI framework
- **Dart 3.9+** — Modern, type-safe language
- **Provider 6.1+** — State management and dependency injection

### ☁️ Backend & Services
- **Firebase** — Authentication, real-time database
- **Supabase** — PostgreSQL-based backend with sync API
- **Google Gemini** — AI-powered career matching and insights

### 🗄️ Data & Storage
- **SQLite** — Local device database
- **Cloud Firestore** — Real-time cloud database
- **SharedPreferences** — Simple key-value storage

### 🛠️ Notable Libraries

| Library | Purpose |
|---------|---------|
| `provider` | State management |
| `firebase_core`, `cloud_firestore`, `firebase_auth` | Backend services |
| `supabase_flutter` | Real-time sync & API |
| `image_picker` | Photo/file selection |
| `google_mlkit_text_recognition` | OCR for document scanning |
| `pdf`, `printing` | PDF generation & export |
| `webview_flutter` | In-app web content |
| `http` | HTTP client for API calls |

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Flutter SDK** 3.9.2 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK** 3.9.2+ (included with Flutter)
- **Android SDK** (API level 24+) for Android development
- **Xcode** 14+ (for iOS development, macOS only)
- **Git** for version control
- A **Firebase account** for backend services
- A **Supabase account** for data synchronization
- A **Google Gemini API key** for AI features

### Verify Installation

```bash
flutter --version
dart --version
flutter doctor
```

---

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/TAYTEMHOE/PathWise.git
cd PathWise
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Set Up Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password)
3. Create a **Realtime Database**
4. Configure for both Android and iOS
5. Place credentials:
   - Android: `android/app/google-services.json`
   - iOS: Update via FlutterFire CLI

### 4. Set Up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Create tables for your data model
3. Generate an API key and anonymous key
4. Update `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 5. Set Up Google Gemini API

1. Get your API key from [Google AI Studio](https://ai.google.dev)
2. Add to your configuration or environment variables
3. Initialize in the app as shown in `lib/main.dart`

### 6. Run the App

```bash
# Development
flutter run

# iOS
flutter run -d ios

# Android
flutter run -d android

# Release
flutter run --release
```

---

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                          # App entry point & initialization
├── routes.dart                        # Named route definitions
│
├── config/                           # Configuration files
│   └── supabase_config.dart         # Supabase credentials
│
├── view/                             # UI Screens & Widgets
│   ├── auth_screen.dart             # Login/signup
│   ├── dashboard.dart               # Main dashboard
│   ├── university_list_screen.dart  # Universities browsing
│   ├── program_list_screen.dart     # Programs browsing
│   ├── ai_match_screen.dart         # AI career matching
│   ├── comparison_screen.dart       # Program comparison
│   ├── profile/                     # User profile screens
│   ├── interview/                   # Interview prep
│   ├── resume/                      # Resume builder
│   └── bottomNavigationBar.dart      # Bottom navigation
│
├── viewModel/                        # Business Logic (MVVM Pattern)
│   ├── auth_view_model.dart         # Authentication logic
│   ├── university_list_view_model.dart
│   ├── program_list_view_model.dart
│   ├── ai_match_view_model.dart     # AI matching logic
│   ├── comparison_view_model.dart
│   ├── profile_view_model.dart
│   ├── interview_view_model.dart
│   ├── resume_view_model.dart
│   └── dashboard_view_model.dart
│
├── repository/                       # Data Access Layer
│   ├── ai_match_repository.dart     # AI matching with Gemini
│   └── [other repositories]
│
├── models/                           # Data Models
│   ├── user.dart
│   ├── university.dart
│   ├── program.dart
│   └── ...
│
├── services/                         # Core Services
│   ├── app_initialization_service.dart   # App setup & sync
│   ├── shared_preference_services.dart
│   └── ...
│
├── utils/                            # Utility Functions
│   ├── shared_preferences_helper.dart
│   └── ...
│
├── widgets/                          # Reusable Components
│   ├── app_loading_screen.dart
│   └── ...
│
└── assets/
    └── images/                      # App images & icons
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/user_test.dart

# Generate coverage
flutter test --coverage
```

### Code Analysis

```bash
# Analyze code
flutter analyze

# Apply linting rules
dart fix --apply

# Format code
dart format lib/
```

### Build Modes

```bash
# Debug
flutter run

# Profile (performance testing)
flutter run --profile

# Release (optimized)
flutter run --release
```

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
FIREBASE_PROJECT_ID=your-firebase-project
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-key
GEMINI_API_KEY=your-gemini-api-key
```

### Firebase Setup via FlutterFire CLI

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### Build Configuration

**Android** (`android/app/build.gradle`):
- Target SDK: 34+
- Min SDK: 24+

**iOS** (`ios/Podfile`):
- Target: iOS 12.0+
- Swift version: 5.0+

---

## 🎯 Key Features Implementation

### AI Career Matching

The app uses **Google Gemini API** for intelligent career recommendations:

```dart
// AI matching considers:
// - User skills, education, experience
// - Career preferences and interests
// - Personality test results (MBTI, RIASEC, Big Five)
// - Available career paths and market data
```

### Offline-First Sync

The three-layer architecture ensures reliability:

1. **SQLite** stores all data locally
2. **Background sync** updates every 6 hours
3. **Conflict resolution** prioritizes recent changes
4. **Network detection** handles connectivity changes

### Personality Tests

Three scientifically-backed assessments:
- **MBTI**: 4 questions × 4 dichotomies = 16 types
- **RIASEC**: 6 interest categories
- **Big Five**: Openness, Conscientiousness, Extraversion, Agreeableness, Neuroticism

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** changes: `git commit -m 'Add amazing feature'`
4. **Push** to branch: `git push origin feature/amazing-feature`
5. **Create** a Pull Request

### Development Guidelines

- Follow Dart style guide: [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Write unit tests for new features
- Update documentation for API changes
- Use meaningful commit messages
- Keep PRs focused and manageable

---

## 🐛 Troubleshooting

### Common Issues

**Q: "Firebase not initialized" error**
```
A: Ensure Firebase is properly configured in main.dart and services are initialized before use.
```

**Q: "Supabase connection failed"**
```
A: Check your API key, URL, and internet connection. Verify in supabase_config.dart.
```

**Q: "SQLite database locked"**
```
A: Ensure only one process accesses the database. Check AppInitializationService.
```

**Q: "Gemini API rate limit exceeded"**
```
A: Implement request throttling and caching in ai_match_repository.dart.
```

For more help, check [Flutter troubleshooting](https://flutter.dev/docs/testing/troubleshooting).

---

## 📊 Performance & Optimization

### Best Practices Implemented

- ✅ Local-first architecture for instant response times
- ✅ Lazy loading for list views (universities, programs)
- ✅ Image caching with `cached_network_image`
- ✅ Efficient database queries with proper indexing
- ✅ Background sync to prevent UI blocking
- ✅ Provider pattern for optimized rebuilds

### Monitoring

- Track sync status and errors
- Monitor database size (visible in initialization logs)
- Profile app performance with Flutter DevTools

---

## 📚 Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Firebase for Flutter](https://firebase.flutter.dev)
- [Supabase Flutter](https://supabase.com/docs/reference/flutter)

### Learning Resources
- [Flutter Codelab](https://codelabs.developers.google.com/?product=flutter)
- [Provider Package Guide](https://pub.dev/packages/provider)
- [Google Gemini API Docs](https://ai.google.dev/docs)

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.

---

## 👨‍💻 Author

**TAYTEMHOE**

- GitHub: [@TAYTEMHOE](https://github.com/TAYTEMHOE)
- Repository: [PathWise](https://github.com/TAYTEMHOE/PathWise)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase and Supabase for backend infrastructure
- Google for Gemini AI capabilities
- The open-source community for excellent packages

---

## 📞 Support

For issues, questions, or suggestions:

1. Check [existing issues](https://github.com/TAYTEMHOE/PathWise/issues)
2. Create a [new issue](https://github.com/TAYTEMHOE/PathWise/issues/new)
3. Contact the maintainer

---

<div align="center">

**Made with ❤️ by TAYTEMHOE**

⭐ If you found this project helpful, please consider starring it!

</div>
