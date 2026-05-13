# NPS Browser (Android) - v0.0.1

A high-performance, premium PSP game manager and downloader for Android. This application allows users to browse the NoPayStation (NPS) database, view detailed game information with dynamic descriptions, and download/decrypt games directly to their device.

Developed by **Talha Salman**.

---

## 🚀 Key Features

### 🎮 Premium Gallery Experience
- **Adaptive Grid Layout**: Choose between "Standard" (3 columns) or "Large" (2 columns) tiles via settings.
- **Vibrant Artwork**: Edge-to-edge cover art fetched dynamically from high-quality community repositories.
- **Hero Transitions**: Smooth, full-screen image transitions when moving from the gallery to game details.
- **Pinch-to-Zoom**: View high-resolution cover art in a full-screen popup with multi-touch support.

### ⚡ Performance Optimized
- **Isolate-Powered Parsing**: The heavy NPS database (thousands of rows) is parsed in a background `Isolate` to ensure zero UI stutter (jank) during startup.
- **Smart Pagination**: Optimized grid rendering with 10-15 items per page to maintain high frame rates even on budget devices.
- **Foreground Download Service**: Reliable background downloads using a dedicated Android Foreground Service with persistent notifications.

### 🔍 Intelligent Discovery
- **Wikipedia Integration**: Automatically fetches real-time game descriptions and summaries from Wikipedia using a smart-search algorithm.
- **Regional Filtering**: Filter the library by region (US, EU, JP, ASIA) with persisted user preferences.
- **Fast Search**: Instant search across titles and Title IDs.

### 📂 Integrated Downloader
- **Direct Decryption**: Automatically decrypts and extracts `.pkg` files into playable formats after downloading.
- **Queue Management**: Monitor progress, cancel ongoing tasks, and clear finished downloads with ease.
- **Custom Storage**: Choose your own `PSP/GAME` folder as the destination for all downloads.

---

## 🛠 Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Material 3)
- **Networking**: [Dio](https://pub.dev/packages/dio) & [HTTP](https://pub.dev/packages/http)
- **Concurrency**: Dart [Isolates](https://api.dart.dev/stable/dart-isolate/dart-isolate-library.html) for background processing.
- **Background Tasks**: [flutter_background_service](https://pub.dev/packages/flutter_background_service)
- **Local Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) for persistence.
- **Image Caching**: [cached_network_image](https://pub.dev/packages/cached_network_image)
- **Parsing**: [CSV](https://pub.dev/packages/csv) for TSV processing.

---

## 📁 Project Structure

```text
lib/
├── models/             # Data structures (PspGame, DownloadTask, etc.)
├── screens/            # Main UI pages (Home, Details, Settings, Downloads)
├── services/           # Business logic (API, Background Service, Decryption, Wikipedia)
├── widgets/            # Reusable UI components (GameCard, Custom Icons)
└── main.dart           # Application entry point and service initialization
```

---

## ⚙️ Installation & Setup

1. **Prerequisites**: Ensure you have the Flutter SDK installed and an Android device running Android 8.0+.
2. **Clone & Build**:
   ```bash
   git clone https://github.com/talhasalman/nps-browser.git
   cd nps-browser
   flutter pub get
   flutter run --release
   ```
3. **Configuration**: On the first launch, go to **Settings** and select your `PSP/GAME` folder. This is required for the app to function.

---

## ⚖️ Disclaimer & AI Assistance

This application is for educational and personal use only. Users are responsible for complying with the terms of service of the data sources utilized.

**AI Assistance Disclosure**:
This project was developed with significant assistance from AI technologies. Specifically, **Google Gemini** and the **Antigravity** coding agent were utilized for architectural design, complex logic implementation, and UI optimization. This collaboration enabled the rapid development of advanced features like background isolate parsing and modern predictive back gesture support.

---
© 2026 Talha Salman. All Rights Reserved.
