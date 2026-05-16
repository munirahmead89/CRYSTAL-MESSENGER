# Crystal Messenger

Crystal Messenger is a cross-platform instant messaging app for Android, iOS, Windows, macOS, and Linux.
It provides secure chat, QR-based device linking, local notifications, and a built-in local server for instant communication.

## Supported Platforms

- Android
- iOS
- Windows
- macOS
- Linux

> Web support is not fully configured in this repository because several native dependencies are mobile/desktop only.

## Build and Release

1. Install dependencies:

```bash
flutter pub get
```

2. Generate launcher icons for mobile platforms:

```bash
flutter pub run flutter_launcher_icons:main
```

3. Build each target:

- Android APK: `flutter build apk --release`
- Android App Bundle: `flutter build appbundle --release`
- iOS: `flutter build ios --release`
- Windows: `flutter build windows --release`
- macOS: `flutter build macos --release`
- Linux: `flutter build linux --release`

## App Branding and Packaging

- App name is set to `Crystal Messenger` for user-facing platforms.
- Android package ID is configured as `com.crystalmessenger.app`.
- iOS and macOS use the platform product bundle identifiers configured in Xcode.
- The app icon is loaded from `assets/images/icon.png`.

## Global Production Build

Use the following commands to produce a global-ready release build for Android and Windows:

```bash
flutter clean && flutter pub get
flutter build apk --release --split-per-abi
flutter build windows --release
```

This prepares the Android APK and Windows EXE for global distribution behind the Cloudflare tunnel.

## Local Server

This repository includes a lightweight local backend in `server/` for features like download management and status polling.
You can build it separately using `build_server.bat` on Windows or `build_server.sh` on macOS/Linux.

## Notes for Users

- Install the app on a supported platform, then open it to start communication instantly.
- The app includes QR-code sharing screens and device linking to make onboarding fast.
- For production mobile publishing, configure Android signing keys and iOS/macOS code signing in Xcode.

For general Flutter guidance, see [https://docs.flutter.dev/](https://docs.flutter.dev/).
