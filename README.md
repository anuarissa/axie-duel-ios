# Axie Duel — iOS shell

Native iOS wrapper (Capacitor 8) for **Axie Duel**, a free tactical card game. The game itself is served from
https://axie-duel.com; this repository only holds the native layer: push notifications, haptics, the offline
screen, the App Store review prompt and the share sheet.

- `capacitor.config.ts` — app id, server URL and the user-agent marker the web uses to switch to its App Store mode.
- `native/ios/` — Swift sources, entitlements, privacy manifest, icon and launch image, UI test, project and plist patches.
- `scripts/gen-ios.sh` — regenerates `ios/` from the pinned Capacitor template (macOS only; `ios/` is never committed).
- `.github/workflows/ios.yml` — simulator build, UI test, video and screenshots.

Signing and App Store uploads happen elsewhere: this repository contains no secrets.

© Axie Duel. All rights reserved.
