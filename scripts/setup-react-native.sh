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
# Exported: avdmanager locates the SDK through the environment, not a flag
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
# Latest stable API level; minor platform releases (e.g. 37.1, 37.2) ship no system images
SYSTEM_IMAGE="system-images;android-37.0;google_apis_playstore;arm64-v8a"
AVD_NAME="Pixel_10_API_37"

if ! command -v sdkmanager >/dev/null 2>&1; then
  echo "sdkmanager not found. Run: brew install --cask android-commandlinetools" >&2
  exit 1
fi

echo "==> Installing Android SDK components"
# Platforms, build-tools and NDK are left to Gradle: it downloads the versions each
# project declares on first build, as long as the licenses below are accepted.
# Gradle never fetches emulator system images, so one is installed here.
yes | sdkmanager --sdk_root="$ANDROID_HOME" \
  "platform-tools" \
  "emulator" \
  "$SYSTEM_IMAGE"

yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1 || true

echo "==> Creating emulator"
if avdmanager list avd -c | grep -qx "$AVD_NAME"; then
  echo "    $AVD_NAME already exists"
else
  # "no" declines the custom hardware profile prompt
  echo no | avdmanager create avd --name "$AVD_NAME" --package "$SYSTEM_IMAGE" --device pixel_10
fi

echo ""
echo "React Native environment is ready (iOS + Android)."
