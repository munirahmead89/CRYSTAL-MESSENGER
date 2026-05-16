#!/usr/bin/env bash
# Crystal Messenger — release packaging (macOS / Linux CI)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Crystal Messenger release build =="
command -v flutter >/dev/null 2>&1 || { echo "Flutter not on PATH"; exit 1; }

flutter pub get

echo "[1/5] Android APK..."
flutter build apk --release

echo "[2/5] Android App Bundle..."
flutter build appbundle --release

echo "[3/5] Windows (requires cross-compile setup on Linux)..."
flutter build windows --release || echo "Windows build skipped (run on Windows CI)."

echo "[4/5] Linux..."
flutter build linux --release

echo "[5/5] macOS (Apple silicon / Intel hosts)..."
if [[ "$(uname -s)" == "Darwin" ]]; then
  flutter build macos --release
  echo "DMG: use create-dmg or productbuild from build/macos/Build/Products/Release/*.app"
else
  echo "macOS build skipped (not Darwin)."
fi

echo "Done. Upload APK/AAB to Play Console; notarize macOS .app before distributing DMG."
