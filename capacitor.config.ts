import type { CapacitorConfig } from '@capacitor/cli';
import { readFileSync } from 'fs';

// Axie Duel iOS shell. The game is served from https://axie-duel.com; this app adds the native layer
// (push notifications, haptics, offline screen, App Store review prompt, share sheet).
const version: string = JSON.parse(readFileSync('package.json', 'utf8')).version;
const ci = process.env.AXD_CI === '1';

const config: CapacitorConfig = {
  appId: 'com.axieduel.app',
  appName: 'Axie Duel',
  webDir: 'www',
  backgroundColor: '#0a0117',
  server: {
    // The query string keeps Capacitor's "same server" prefix check from matching look-alike hosts.
    url: 'https://axie-duel.com/?src=ios',
    // Host check runs before the prefix check: every page of the site stays inside the app.
    allowNavigation: ['axie-duel.com', 'www.axie-duel.com'],
    errorPath: 'offline.html',
  },
  ios: {
    // The web switches to its App Store mode when it sees this marker (never trusted for anything else).
    appendUserAgent: `AxieDuelApp/${version} (iOS${ci ? '; CI' : ''})`,
    contentInset: 'never',
    limitsNavigationsToAppBoundDomains: false,
    allowsLinkPreview: false,
  },
  plugins: {
    PushNotifications: {
      presentationOptions: ['banner', 'list', 'sound', 'badge'],
    },
  },
};

export default config;
