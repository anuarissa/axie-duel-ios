#!/usr/bin/env bash
# Generates ios/ from the pinned Capacitor template and applies Axie Duel's native files. macOS (CI) only:
# ios/ is never committed; it is rebuilt from package-lock.json + native/ on every build.
#   AXD_CI=1 bash scripts/gen-ios.sh          # CI simulator build (user agent gets "; CI")
#   TEAM_ID=XXXXXXXXXX bash scripts/gen-ios.sh  # release build (manual signing settings)
set -euo pipefail
cd "$(dirname "$0")/.."
[ "$(uname)" = "Darwin" ] || { echo "gen-ios.sh must run on macOS"; exit 1; }

ruby -e "require 'xcodeproj'" 2>/dev/null || gem install xcodeproj --no-document

rm -rf ios
npx cap telemetry off >/dev/null 2>&1 || true
npx cap add ios --packagemanager SPM

for f in ios/App/App/AppDelegate.swift ios/App/App/SceneDelegate.swift ios/App/App/Info.plist \
         ios/App/App.xcodeproj/project.pbxproj ios/App/App/Assets.xcassets/AppIcon.appiconset/Contents.json; do
  [ -f "$f" ] || { echo "Capacitor template changed: missing $f"; exit 1; }
done

cp native/ios/App/AppDelegate.swift native/ios/App/SceneDelegate.swift \
   native/ios/App/App.entitlements native/ios/App/PrivacyInfo.xcprivacy ios/App/App/
rm -rf ios/App/App/Assets.xcassets/AppIcon.appiconset ios/App/App/Assets.xcassets/Splash.imageset
cp -R native/ios/App/Assets.xcassets/AppIcon.appiconset native/ios/App/Assets.xcassets/Splash.imageset \
      ios/App/App/Assets.xcassets/
mkdir -p ios/App/AppUITests
cp native/ios/AppUITests/AppUITests.swift ios/App/AppUITests/

bash native/ios/patch-plist.sh ios/App/App/Info.plist
ruby native/ios/patch-project.rb ios/App/App.xcodeproj
npx cap sync ios

echo "ios/ generated ($(node -p "require('./package.json').version"))"
