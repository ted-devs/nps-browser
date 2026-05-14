# NPS Browser (Android) 🎮

[![Release](https://img.shields.io/github/v/release/ted-devs/nps-browser?include_prereleases&style=for-the-badge)](https://github.com/ted-devs/nps-browser/releases)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)

A high-performance, premium PSP game manager and downloader for Android. Browse, search, and download your favorite PSP titles directly to your device with automatic decryption.

Developed by **Talha Salman**.

---

## 📥 Quick Start (For Users)

1. **Download the App**: Get the latest `.apk` from our [Releases Page](https://github.com/ted-devs/nps-browser/releases).
2. **Install**: Open the downloaded file and install it on your Android device (ensure "Install from Unknown Sources" is enabled).
3. **Grant Permissions**: Upon first launch, the app will request **Notification** and **All Files Access**. These are required to notify you of download progress and save games to your chosen folder.
4. **Setup Storage**: Go to **Settings** ⚙️ and pick your preferred game folder (e.g., your `PSP/GAME` folder).
5. **Start Playing**: Find a game you like, hit download, and wait for the extraction to finish. The game will be ready to play in your favorite emulator!

---

## 🚀 Key Features

### 🎮 Premium Gallery Experience
- **Adaptive Grid Layout**: Switch between high-density and large-tile views.
- **Vibrant Artwork**: Edge-to-edge cover art fetched dynamically.
- **Hero Transitions**: Smooth, full-screen transitions between pages.
- **Wikipedia Integration**: Real-time game summaries and history fetched automatically.

### 📂 Integrated Downloader & Decryptor
- **Automatic Extraction**: No need for external tools; the app decrypts `.pkg` files into playable formats automatically.
- **On-Demand Background Service**: The downloader starts only when needed and stops when finished to save battery.
- **Retry Logic**: Automatically handles network glitches or timed-out connections.
- **Storage Cleanup**: Intelligent cleanup of temporary files to keep your storage lean.

### ⚡ Performance First
- **Isolate-Powered Parsing**: Thousands of database rows are parsed in the background to ensure zero lag.
- **Smart Pagination**: Optimized for smooth scrolling even on budget devices.

---

## 🛠 Developer Setup

If you want to build the project from source:

1. **Prerequisites**: [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
2. **Clone the Repo**:
   ```bash
   git clone https://github.com/ted-devs/nps-browser.git
   cd nps-browser
   ```
3. **Get Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Build & Run**:
   ```bash
   flutter run --release
   ```

---

## ⚖️ Disclaimer & AI Assistance

This application is for educational and personal use only. Users are responsible for complying with the terms of service of the data sources utilized.

**AI Assistance Disclosure**:
This project was developed with significant assistance from AI technologies. Specifically, **Google Gemini** and the **Antigravity** coding agent were utilized for architectural design, complex logic implementation, and UI optimization. This collaboration enabled the rapid development of advanced features like background isolate parsing and native C++ decryption wrappers.

---
© 2026 Talha Salman. All Rights Reserved.
