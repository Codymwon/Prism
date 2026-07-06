# Script to build a secure, obfuscated release APK for Prism.
# Keeps debug symbols separate and secure.

Write-Host "Cleaning build directory..." -ForegroundColor Cyan
flutter clean

Write-Host "Fetching dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host "Building obfuscated Android release APK..." -ForegroundColor Cyan
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

Write-Host "Build complete! Release APK: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
Write-Host "Debug symbols stored at: build/app/outputs/symbols" -ForegroundColor Green
