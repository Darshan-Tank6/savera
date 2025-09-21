# Savera 🚨

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-green)](https://flutter.dev/multi-platform)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 🌍 Overview

**Savera** is a **disaster management and emergency communication app** built with Flutter.
It enables people to **communicate without internet** using mesh networking, send **SOS alerts**, share **location & roles (Helper / Victim / Rescuer)**, and stay connected in crisis situations.

---

## ✨ Features

- 🔗 **Mesh Networking** – Peer-to-peer discovery & communication
- 🆘 **SOS Tab** – Quickly send emergency alerts
- 📍 **Location Sharing** – Share & view user coordinates
- 👥 **Role Selection** – Choose role: _Helper_, _Rescuer_, _Victim_
- 💬 **Offline Chat** – Communicate without internet
- 📦 **Local Storage** – Save user details & chat history
- 🌈 **Cross-Platform UI** – Runs on Android, iOS, Web, Desktop

---

## 📸 Screenshots

<!-- _(Add screenshots of your app here)_ -->

<!-- <p align="center">
  <img src="screenshots/role_selector.png" width="250" />
  <img src="screenshots/chat.png" width="250" />
  <img src="screenshots/sos.png" width="250" />
</p> -->

---

## 🗷 Architecture

- **Flutter (Dart)** → App logic & UI (`lib/`)
- **Nearby / Bluetooth APIs** → For discovery & mesh connections
- **Local Storage (Hive / Drift planned)** → User + chat persistence
- **Platform Code (Kotlin / Swift)** → Native integration for Bluetooth & location

---

## 🗂 Directory Structure

```
savera/
├── lib/
│   ├── chat.dart          # Chat screen
│   ├── mesh.dart          # Mesh networking logic
│   ├── user_config.dart   # User details (name, role, etc.)
│   ├── role_selector.dart # Role selection UI
│   ├── helper_home.dart   # Helper dashboard
│   └── landing_page.dart  # App entry screen
├── android/               # Native Android code
├── ios/                   # Native iOS code
├── web/                   # Web app
├── linux/, macos/, windows/ # Desktop builds
├── test/                  # Unit & widget tests
└── pubspec.yaml           # Dependencies
```

---

## 📦 Dependencies

Key Flutter packages:

- [`permission_handler`](https://pub.dev/packages/permission_handler) → Runtime permissions
- [`geolocator`](https://pub.dev/packages/geolocator) → Location services
- [`intl`](https://pub.dev/packages/intl) → Date/time formatting
- _(Planned)_ [`hive`](https://pub.dev/packages/hive) / [`drift`](https://pub.dev/packages/drift) → Local storage

---

## 🚀 Getting Started (Developers)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio / VS Code / Xcode
- Device or emulator

### Installation

```bash
# Clone repo
git clone https://github.com/Darshan-Tank6/savera.git
cd savera

# Install dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on Web
flutter run -d chrome
```

---

## 🧑‍ 🧑 Usage (Users)

1. Launch the app
2. **Select your role** (Helper, Rescuer, Victim)
3. Allow permissions (Location, Bluetooth)
4. Use **SOS Tab** for distress signals
5. Chat & share location via **mesh networking**

---

## 🧪 Testing

```bash
flutter test
```

---

## 🤝 Contributing

Contributions are welcome!

1. Fork this repo
2. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature
   ```

3. Commit your changes
4. Push branch & open Pull Request

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Darshan Tank**
[GitHub](https://github.com/Darshan-Tank6)

---
