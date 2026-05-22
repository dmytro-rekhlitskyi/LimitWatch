# LimitWatch

**LimitWatch** is a native iOS + Apple Watch app that gives you an always-visible view of your Claude AI usage limits — directly on your wrist, Home Screen, and Watch Face.

Track your 5-hour and 7-day rate limits in real time with color-coded progress, reset countdowns, and two distinct visual styles.

---

## Features at a Glance

| Platform | What you get |
|---|---|
| **iPhone** | Full status view, sign-in flow, watch style picker, account management |
| **Apple Watch** | Live usage rings or bars synced from iPhone, double-tap to refresh |
| **Widgets & Complications** | 4 widget types for Lock Screen, Home Screen, and Watch Face |

---

## iPhone App

### Status Tab
The main screen shows both rate limit windows at a glance:

- **5-hour limit** — short-term token usage with countdown to reset
- **7-day limit** — weekly token usage with countdown to reset
- Color-coded progress bars: green below 70 %, orange 70–89 %, red at 90 %+
- Relative "last updated" timestamp
- Manual refresh button

### Watch Style Tab
Choose how usage is displayed on your Apple Watch:

- **Claude Style** — two horizontal progress bars on a warm dark background, matching Claude's brand colors
- **Apple Style** — concentric rings inspired by the Fitness app, with red-orange and cyan-blue gradients

The selection syncs to the watch instantly.

### Account Tab
- Sign in via the embedded Claude.ai web view (supports Google, Apple, GitHub, and Microsoft)
- Displays your connected organization name
- One-tap sign-out with confirmation
- Session key stored securely in the iOS Keychain

---

## Apple Watch App

The Watch app receives data from the iPhone over WatchConnectivity and renders it in your chosen style.

### Claude Style
Two stacked progress blocks on a dark background — label, percentage, animated bar, and time until reset for each window.

### Apple Style
Two concentric rings on a black background. Percentages are shown in the center; colored labels and reset times sit below the rings.

**Double-tap** on either style to request a fresh data pull from the iPhone.

---

## Widgets & Complications

Four widget families are supported across iPhone Lock Screen, Home Screen, and Apple Watch faces:

| Widget | Description |
|---|---|
| **Circular** | Two concentric arcs with the 5-hour percentage in the center |
| **Rectangular** | Two labeled progress bars with reset countdowns |
| **Inline** | Single-line summary — `5h 75% · 7d 45%` |
| **Corner** *(watchOS only)* | Gauge arc with a clock icon for the 5-hour limit |

Widgets refresh every 15 minutes using cached data from a shared App Group container.

---

## How It Works

1. **Sign in** — LimitWatch opens claude.ai in an in-app browser and captures your session cookie after you log in. The session key is stored in the Keychain and never leaves your device.
2. **Fetch** — The app calls the Claude.ai API to read your current token consumption and reset timestamps.
3. **Sync** — iPhone pushes the latest data to the Watch and widget container via WatchConnectivity and App Groups.
4. **Display** — Percentages, progress visuals, and reset countdowns update everywhere automatically.

---

## Tech Stack

- **SwiftUI** — all UI across iOS and watchOS
- **WidgetKit** — Home Screen widgets and Watch Face complications
- **WatchConnectivity** — real-time data sync between iPhone and Apple Watch
- **WebKit** — in-app login flow for Claude.ai authentication
- **Keychain (Security framework)** — secure credential storage
- **App Groups / UserDefaults** — shared data container for widgets
- **URLSession** — API calls to claude.ai

---

## Requirements

- iPhone running **iOS 17+**
- Apple Watch running **watchOS 10+** *(optional)*
- An active **Claude.ai account**

---

## Privacy

LimitWatch does not collect or transmit any personal data. Your session key is stored exclusively in the iOS Keychain on your device and is used solely to fetch your own usage statistics from Claude.ai.

---

## License

[MIT](LICENSE)
