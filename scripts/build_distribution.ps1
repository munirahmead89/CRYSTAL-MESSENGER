#Requires -Version 5.1
<#
.SYNOPSIS
  Builds Crystal Messenger release artifacts for Google Drive / sideload distribution.

.PARAMETER ApiBaseUrl
  Public or LAN URL of your Crystal server, e.g. https://api.example.com or http://192.168.1.5:8080

.PARAMETER WsUrl
  Optional full WebSocket URL. If empty, the client derives ws/wss from ApiBaseUrl.

.PARAMETER SkipAndroid
.PARAMETER SkipWindows
.PARAMETER SkipLinux
.PARAMETER SkipMacOS
#>
param(
  [Parameter(Mandatory = $true)]
  [string] $ApiBaseUrl,

  [string] $WsUrl = "",

  [switch] $SkipAndroid,
  [switch] $SkipWindows,
  [switch] $SkipLinux,
  [switch] $SkipMacOS
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$dist = Join-Path $root "distribution"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$defines = @(
  "--dart-define=API_BASE_URL=$ApiBaseUrl"
)
if ($WsUrl -ne "") {
  $defines += "--dart-define=WS_URL=$WsUrl"
}

Write-Host "Project root: $root"
Write-Host "API_BASE_URL: $ApiBaseUrl"
flutter pub get

if (-not $SkipAndroid) {
  Write-Host "`n=== Android APK ===" -ForegroundColor Cyan
  flutter build apk --release @defines
  $apk = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
  if (Test-Path $apk) {
    Copy-Item $apk (Join-Path $dist "CrystalMessenger-Android.apk") -Force
  }
}

if (-not $SkipWindows) {
  Write-Host "`n=== Windows ===" -ForegroundColor Cyan
  flutter build windows --release @defines
  $winOut = Join-Path $root "build\windows\x64\runner\Release"
  if (Test-Path $winOut) {
    $zip = Join-Path $dist "CrystalMessenger-Windows-x64.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path (Join-Path $winOut "*") -DestinationPath $zip
  }
}

if (-not $SkipLinux) {
  Write-Host "`n=== Linux ===" -ForegroundColor Cyan
  flutter build linux --release @defines
  $linuxBundle = Join-Path $root "build\linux\x64\release\bundle"
  if (Test-Path $linuxBundle) {
    $tgz = Join-Path $dist "CrystalMessenger-Linux-x64.tar.gz"
    if (Test-Path $tgz) { Remove-Item $tgz -Force }
    tar -czf $tgz -C (Split-Path $linuxBundle) (Split-Path -Leaf $linuxBundle)
  }
}

if (-not $SkipMacOS) {
  Write-Host "`n=== macOS ===" -ForegroundColor Cyan
  flutter build macos --release @defines
  $macApp = Join-Path $root "build\macos\Build\Products\Release\crystal_messenger.app"
  if (Test-Path $macApp) {
    $zip = Join-Path $dist "CrystalMessenger-macOS.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path $macApp -DestinationPath $zip
  }
}

Write-Host "`nDone. Upload the contents of: $dist" -ForegroundColor Green
Write-Host "Tip: edit assets\config\server_endpoints.json before build instead of dart-define if you prefer baked-in URLs."
