#!/usr/bin/env bash
# Axie Duel Info.plist settings on top of the Capacitor template (macOS only: uses plutil).
set -euo pipefail
P="${1:?usage: patch-plist.sh path/to/Info.plist}"

plutil -replace CFBundleDisplayName -string "Axie Duel" "$P"
# Landscape-only iPhone game (the web already lays out for landscape; the Android app is landscape too).
plutil -replace UISupportedInterfaceOrientations -json '["UIInterfaceOrientationLandscapeRight","UIInterfaceOrientationLandscapeLeft"]' "$P"
plutil -remove 'UISupportedInterfaceOrientations~ipad' "$P" 2>/dev/null || true
# Capacitor reads this in setStatusBarDefaults(): full-screen game, no status bar.
plutil -replace UIStatusBarHidden -bool YES "$P"
# HTTPS only: exempt from export compliance documentation.
plutil -replace ITSAppUsesNonExemptEncryption -bool NO "$P"
plutil -replace UIUserInterfaceStyle -string Dark "$P"
plutil -replace UIRequiredDeviceCapabilities -json '["arm64"]' "$P"

plutil -lint "$P"
echo "Info.plist patched"
