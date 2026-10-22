#!/usr/bin/env bash
set -e

# Auto-detect Flutter PATH on Linux if not set
if ! command -v flutter &> /dev/null; then
  if [ -d "$HOME/development/flutter/bin" ]; then
    export PATH="$PATH:$HOME/development/flutter/bin"
  fi
fi

# Load REVENUECAT_API_KEY from .env if present
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

KEY="${REVENUECAT_API_KEY:-}"
if [ -z "$KEY" ]; then
  echo -e "\033[0;33mWarning: REVENUECAT_API_KEY is not set. Building without RevenueCat key.\033[0m"
fi

echo -e "\033[0;36mCleaning build directory...\033[0m"
flutter clean

echo -e "\033[0;36mFetching dependencies...\033[0m"
flutter pub get

echo -e "\033[0;36mBuilding obfuscated Android release App Bundle (.aab)...\033[0m"
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=REVENUECAT_API_KEY="$KEY"

echo -e "\033[0;36mBuilding obfuscated Android release APK...\033[0m"
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols --dart-define=REVENUECAT_API_KEY="$KEY"

echo -e "\033[0;32mBuild complete!\033[0m"
echo -e "\033[0;32mRelease App Bundle (.aab): build/app/outputs/bundle/release/app-release.aab\033[0m"
echo -e "\033[0;32mRelease APK: build/app/outputs/flutter-apk/app-release.apk\033[0m"
echo -e "\033[0;32mDebug symbols stored at: build/app/outputs/symbols\033[0m"
