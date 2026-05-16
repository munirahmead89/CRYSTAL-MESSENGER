# Crystal Messenger — release packaging (Windows host)
# Prerequisites: Flutter SDK on PATH, Android SDK, JDK 17+, optional Visual Studio (Windows desktop), optional Xcode (macOS builds only run on macOS).
# This script never bundles JDK/SDK inside the repo; it validates common env vars and runs official Flutter build targets.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "== Crystal Messenger release build ==" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Flutter SDK not found on PATH."
}

flutter pub get

Write-Host "`n[1/5] Android APK..." -ForegroundColor Yellow
flutter build apk --release

Write-Host "`n[2/5] Android App Bundle..." -ForegroundColor Yellow
flutter build appbundle --release

Write-Host "`n[3/5] Windows EXE..." -ForegroundColor Yellow
flutter build windows --release

Write-Host "`n[4/5] Linux bundle..." -ForegroundColor Yellow
try {
  flutter build linux --release
} catch {
  Write-Warning "Linux build skipped or failed (WSL/Linux toolchain required)."
}

Write-Host "`n[5/5] macOS (host must be macOS)..." -ForegroundColor Yellow
if ($IsMacOS -or $env:OS -eq "Darwin") {
  flutter build macos --release
  Write-Host "Create a .dmg with create-dmg or Disk Utility from build/macos/Build/Products/Release/."
} else {
  Write-Warning "macOS .app builds require a Mac. Run the same script section on macOS."
}

Write-Host "`nArtifacts (typical paths):" -ForegroundColor Green
Write-Host "  APK:   build/app/outputs/flutter-apk/app-release.apk"
Write-Host "  AAB:   build/app/outputs/bundle/release/app-release.aab"
Write-Host "  Win:   build/windows/x64/runner/Release/"
Write-Host "  Linux: build/linux/x64/release/bundle/"
Write-Host "`nStart the backend: cd server; dart run bin/server.dart" -ForegroundColor Cyan
