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

XCODE_APP="/Applications/Xcode.app"

if [[ ! -d "$XCODE_APP" ]]; then
  echo "Xcode not found at $XCODE_APP." >&2
  echo "Install it first: xcodes install --latest --experimental-unxip" >&2
  exit 1
fi

sudo xcode-select --switch "$XCODE_APP/Contents/Developer"
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch

echo ""
echo "Xcode configured."
echo "To add iOS Simulators: xcodes runtimes install 'iOS 18'"
echo "React Native iOS environment is ready."
