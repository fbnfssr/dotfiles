#!/usr/bin/env bash
# Finalises the iOS / React Native environment after Xcode is installed.
#
# Prerequisites:
#   1. bootstrap.sh has been run
#   2. Xcode has been installed:
#        xcodes install --latest --experimental-unxip
#
# Usage:
#   bash ~/dotfiles/scripts/setup-react-native.sh
set -euo pipefail

# Find Xcode — prefer /Applications/Xcode.app, then any Xcode-*.app
if [[ -d "/Applications/Xcode.app" ]]; then
  XCODE_APP="/Applications/Xcode.app"
elif XCODE_APP="$(ls -d /Applications/Xcode-*.app 2>/dev/null | sort -V | tail -1)" && [[ -d "$XCODE_APP" ]]; then
  : # found a versioned Xcode
else
  echo "Xcode not found in /Applications." >&2
  echo "Install it first: xcodes install --latest --experimental-unxip" >&2
  exit 1
fi

echo "Using $XCODE_APP"

sudo xcode-select --switch "$XCODE_APP/Contents/Developer"
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch

echo ""
echo "Xcode configured."

# --- Android SDK (headless — no Android Studio) ---
ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"

if ! command -v sdkmanager >/dev/null 2>&1; then
  echo "sdkmanager not found. Run: brew install --cask android-commandlinetools" >&2
  exit 1
fi

echo "==> Installing Android SDK components"
yes | sdkmanager --sdk_root="$ANDROID_HOME" \
  "platform-tools" \
  "build-tools;35.0.0" \
  "platforms;android-35" \
  "emulator"

yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1 || true

echo ""
echo "React Native environment is ready (iOS + Android)."
