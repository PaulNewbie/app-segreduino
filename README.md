# SegreDuino Mobile App

A Flutter-based mobile application for the SegreDuino Smart Waste Management System. The app provides real-time bin level monitoring, schedule management, task tracking, and push notifications through a dedicated backend API.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Authentication](#authentication)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Ensure the following tools are installed before proceeding:

| Tool | Purpose |
|---|---|
| [Git](https://git-scm.com/downloads) | Version control |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Mobile app framework |
| [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) | IDE with Flutter and Dart extensions |

Verify your Flutter installation by running:

```bash
flutter doctor
```

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/PaulNewbie/app-segreduino.git
cd app-segreduino
```

### 2. Install Dependencies

Fetch all required Flutter packages:

```bash
flutter pub get
```

### 3. Configure the Backend Connection

The app communicates with a PHP backend. Open `lib/service/api_service.dart` and set the `baseUrl` to match your current environment.

```dart
class ApiConfig {
  // Option A — Production server
  // static const String baseUrl = 'https://floralwhite-mule-302326.hostingersite.com';

  // Option B — Local development (replace with your machine's IPv4 address)
  static const String baseUrl = 'http://192.168.x.x:8000';
}
```

> **Important:** When running on a physical Android device or an Android emulator, `localhost` and `127.0.0.1` will not resolve to your development machine. Use your computer's actual local IPv4 address instead (e.g., `192.168.1.5`).
>
> To find your IPv4 address:
> - **Windows:** Run `ipconfig` in Command Prompt and look for the IPv4 Address under your active adapter.
> - **macOS / Linux:** Run `ifconfig` or `ip addr` and look for the `inet` value under your active interface (e.g., `en0` or `eth0`).

### 4. Run the Application

Connect a physical device via USB (with USB debugging enabled) or launch an emulator, then run:

```bash
flutter run
```

To target a specific device when multiple are connected:

```bash
flutter devices          # list available devices
flutter run -d <device-id>
```

---

## Project Structure

```
lib/
├── screen/        # UI screens — Login, Dashboard, Tasks, Bin Levels, etc.
├── service/       # API service layer for backend communication
└── helper/        # Database helpers and shared utility functions

assets/
├── images/        # Image assets
└── fonts/         # Custom font files
```

---

## Authentication

The app supports two authentication methods:

- **Username and password** — Standard credential-based login via the backend API.
- **Facebook Login** — OAuth-based login through the Facebook SDK.

If testing Facebook Login in a local development environment, you must register your machine's debug key hash in the [Facebook Developer Console](https://developers.facebook.com/) under your app's Android settings. Without this, Facebook authentication will fail silently.

To generate your debug key hash:

```bash
# macOS / Linux
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64

# Windows
keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" | openssl sha1 -binary | openssl base64
```

Use `android` as the keystore password when prompted.

---

## Troubleshooting

**The app builds but API requests fail or time out.**
Verify that `ApiConfig.baseUrl` is set to your machine's current local IP address, not `localhost`. IP addresses can change when you reconnect to a network — check that yours has not changed since you last ran the app.

**`flutter pub get` fails with dependency errors.**
Run `flutter clean` followed by `flutter pub get` to clear cached build artifacts and retry.

**Facebook Login fails on device.**
Confirm that your debug key hash is registered in the Facebook Developer Console and that the package name matches what is defined in `android/app/build.gradle`.

**`flutter doctor` reports missing dependencies.**
Follow the platform-specific setup steps in the [official Flutter docs](https://docs.flutter.dev/get-started/install) to resolve any missing tools or SDKs.