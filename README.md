<p align="center">
  <img src="icon.png" width="128" alt="PushForge Icon"/>
</p>

<h1 align="center">PushForge</h1>

<p align="center">
  <strong>The missing push notification tool for mobile &amp; web developers.</strong><br/>
  Craft, send, and test push payloads on iOS Simulators, Android Emulators &amp; macOS Desktop — zero config, zero cost.
</p>

<p align="center">
  <a href="https://developer.apple.com/xcode/"><img src="https://img.shields.io/badge/Xcode-16%2B-blue?logo=xcode&logoColor=white" alt="Xcode 16+"/></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white" alt="macOS 14+"/></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift&logoColor=white" alt="Swift 5.9+"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/tests-12%20passing-brightgreen" alt="Tests"/>
  <img src="https://img.shields.io/badge/templates-16-blueviolet" alt="16 Templates"/>
</p>

---

<p align="center">
  <img src="demo.png" alt="PushForge — send push notifications to iOS Simulator, Android Emulator, and macOS Desktop" width="800"/>
  <br/>
  <em>Craft a payload, pick a target, hit Send. Notification appears instantly on iOS, Android, or macOS.</em>
</p>

---

## Why PushForge?

Every mobile developer has been here: you need to test a push notification, and what should take 10 seconds turns into a 10-minute detour:

1. Find the simulator UDID (`xcrun simctl list devices`... scroll... copy the UUID)
2. Write valid APNs JSON from memory (was it `alert.title` or `aps.alert.title`?)
3. Save it to a temp file
4. Run `xcrun simctl push <that-uuid-you-copied> <bundle-id> /path/to/file.json`
5. Typo in the JSON? Start over.

**This workflow breaks your flow dozens of times a day.**

PushForge eliminates every one of these steps. Open the app, pick a template, hit Send. The notification appears instantly. No terminal. No UUIDs. No temp files. No broken JSON.

### Who is this for?

- **iOS developers** testing notification handling, deep links, or UI updates triggered by push
- **Android developers** testing notification behavior on emulators
- **Web/Desktop developers** previewing how push notifications look in macOS Notification Center
- **QA engineers** verifying notification content, badge counts, and sound behavior
- **Backend developers** validating push payload structure before deploying server changes
- **Teams** that need a shared, visual way to test notification payloads

### How it compares

| Tool | Platform | iOS Sim | Android Emu | Desktop/Web | Free | Maintained |
|---|---|---|---|---|---|---|
| **PushForge** | macOS (native) | Yes | Yes | Yes | Yes | Yes |
| Knuff | macOS | No | No | No | Yes | Abandoned (2019) |
| NWPusher | macOS | No | No | No | Yes | Archived |
| Pusher | macOS | Yes | No | No | No ($15) | Yes |
| curl + terminal | Any | Yes | No | No | Yes | N/A |

PushForge is the only **free, multi-platform push notification tool** with native macOS UI supporting iOS, Android, and Desktop/Web.

---

## Features

### Multi-Platform Push

| Target | How it works | Setup needed |
|---|---|---|
| **iOS Simulator** | `xcrun simctl push` | Xcode |
| **Android Emulator** | `adb shell cmd notification post` | Android Studio |
| **Desktop/Web** | `osascript` with target app icon | None |

Switch between platforms with a single segmented picker. PushForge handles all the plumbing.

### Core Features

- **Visual Payload Composer** — Edit JSON with live validation, byte counter, format/minify buttons
- **Smart JSON Diagnostics** — Detects smart quotes, trailing commas, mismatched braces with exact line:col and fix suggestions
- **Auto-fix** — One-click repair for smart quotes and copy-paste artifacts
- **16 Built-in Templates** — iOS (APNs), Android (FCM), and Web Push formats
- **One-Click Simulator Boot** — Boot any iOS Simulator directly from PushForge
- **Notification History** — Every sent notification logged with status, timestamp, full payload (SwiftData)
- **Save Devices** — Label and save simulator + bundle ID combos for quick reuse
- **Bundle ID Picker** — Dropdown with 40+ pre-installed app IDs across all platforms (including Microsoft Teams)
- **Target App Icon** — Desktop notifications show the selected app's icon (Safari, Slack, Teams, etc.)
- **Cmd+/Cmd- Zoom** — Zoom In, Zoom Out, Reset (Cmd+0) for the JSON editor, persists across sessions
- **Auto-Refresh** — Simulator/emulator list updates when you switch back to PushForge
- **Keyboard Shortcuts** — `Cmd+Enter` to send
- **Lightweight** — Native SwiftUI, no Electron, no runtime dependencies

## Push Payload Formats — iOS vs Android vs Web

Push notification payloads are **fundamentally different** across platforms. PushForge handles all three:

<table>
<tr><th>Feature</th><th>iOS (APNs)</th><th>Android (FCM)</th><th>Web Push</th></tr>
<tr><td><strong>Root key</strong></td><td><code>aps</code></td><td><code>notification</code> / <code>data</code></td><td>Top-level</td></tr>
<tr><td><strong>Title</strong></td><td><code>aps.alert.title</code></td><td><code>notification.title</code></td><td><code>title</code></td></tr>
<tr><td><strong>Body</strong></td><td><code>aps.alert.body</code></td><td><code>notification.body</code></td><td><code>body</code></td></tr>
<tr><td><strong>Badge</strong></td><td><code>aps.badge</code> (number)</td><td><code>notification_count</code></td><td><code>badge</code> (icon URL)</td></tr>
<tr><td><strong>Sound</strong></td><td><code>aps.sound</code></td><td><code>notification.sound</code></td><td>N/A (OS default)</td></tr>
<tr><td><strong>Image</strong></td><td><code>mutable-content</code> + Service Extension</td><td><code>notification.image</code> (URL)</td><td><code>image</code> (URL)</td></tr>
<tr><td><strong>Actions</strong></td><td><code>category</code> (registered in app)</td><td><code>click_action</code></td><td><code>actions[]</code> array</td></tr>
<tr><td><strong>Grouping</strong></td><td><code>thread-id</code></td><td><code>tag</code> + <code>channel_id</code></td><td><code>tag</code></td></tr>
<tr><td><strong>Priority</strong></td><td><code>interruption-level</code></td><td><code>android.priority</code></td><td><code>requireInteraction</code></td></tr>
<tr><td><strong>Silent/Data</strong></td><td><code>content-available: 1</code></td><td><code>data</code> (no <code>notification</code>)</td><td>N/A</td></tr>
<tr><td><strong>Channel</strong></td><td>N/A</td><td><code>channel_id</code></td><td>N/A</td></tr>
</table>

**Example — same notification across platforms:**

<details>
<summary><strong>iOS (APNs)</strong></summary>

```json
{
  "aps": {
    "alert": {
      "title": "New Message",
      "body": "You have a new message waiting."
    },
    "badge": 3,
    "sound": "default"
  }
}
```
</details>

<details>
<summary><strong>Android (FCM)</strong></summary>

```json
{
  "notification": {
    "title": "New Message",
    "body": "You have a new message waiting.",
    "sound": "default",
    "notification_count": 3,
    "channel_id": "messages"
  }
}
```
</details>

<details>
<summary><strong>Web Push</strong></summary>

```json
{
  "title": "New Message",
  "body": "You have a new message waiting.",
  "icon": "/icons/app-icon-192.png",
  "badge": "/icons/badge-72.png",
  "tag": "new-message"
}
```
</details>

## Templates

PushForge ships with **24 ready-to-use templates** loaded from external JSON files:

| Category | Count | Templates |
|---|---|---|
| **Basic** | 1 | Basic Alert |
| **Badge** | 1 | Badge + Sound |
| **Silent** | 2 | Silent Push, Background Sync |
| **Rich** | 2 | Rich Media, Actionable |
| **Advanced** | 5 | Long Payload, Grouped Thread, Critical Alert, Live Activity, Time Sensitive |
| **Android** | 11 | Basic, Data, Rich, Badge+Sound, Silent, Actionable, Long Payload, Grouped, High Priority, Time Sensitive, Image |
| **Web/Desktop** | 2 | Web Basic, Web Actions |

**Android now has full parity with iOS** — every iOS template type has an Android equivalent.

### Custom Templates

Drop a `.json` file into `~/Library/Application Support/PushForge/Templates/` and it appears in the app instantly:

```json
{
  "id": "my_custom",
  "name": "My Custom Template",
  "description": "Custom notification payload",
  "category": "alert",
  "payload": {
    "aps": { "alert": { "title": "Custom", "body": "Hello!" } }
  }
}
```

User templates override bundled ones with the same ID. Organize by subdirectory (`ios/`, `android/`, `web/`) or put them loose in the root.

## Quick Start

### Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 16+ with iOS Simulator runtimes (for iOS)
- Android Studio with ADB (for Android — optional)

### Build & Run

```bash
# Clone the repo
git clone https://github.com/VikrantSingh01/PushForge.git
cd PushForge

# Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate

# Open in Xcode and run
open PushForge.xcodeproj
```

Or build from command line:

```bash
xcodebuild -project PushForge.xcodeproj -scheme PushForge -destination 'platform=macOS' build
```

### First Push in 30 Seconds

1. Launch PushForge
2. Select a platform: **iOS Simulator**, **Android Emulator**, or **Desktop/Web**
3. For iOS: click **Boot** next to any simulator. For Desktop: it's always ready.
4. Pick a template and select an app from the bundle ID dropdown
5. Press **Cmd+Enter** or click **Send Push**

The notification appears instantly.

### Run Tests

```bash
xcodebuild -project PushForge.xcodeproj -scheme PushForgeTests -destination 'platform=macOS' test
```

12 tests covering payload validation, template integrity, simulator bridge, and shell execution.

## Architecture

```
PushForge/
├── Models/          SwiftData models (SavedDevice, NotificationRecord, PayloadTemplate)
├── Services/
│   ├── SimulatorBridge.swift        iOS Simulator (xcrun simctl)
│   ├── ADBBridge.swift              Android Emulator (adb)
│   ├── DesktopNotificationBridge.swift  macOS Desktop (osascript)
│   ├── PayloadValidator.swift       Smart JSON diagnostics + auto-fix
│   └── TemplateManager.swift        16 built-in templates
├── ViewModels/      @Observable state (PayloadComposerVM, DeviceManagerVM)
├── Views/           SwiftUI views (PayloadComposer, SendPanel, History, etc.)
└── Utilities/       ShellExecutor (Process wrapper), JSONFormatter
```

**Key design decisions:**

- **`actor` services** — SimulatorBridge, ADBBridge, ShellExecutor are actors for thread-safe I/O
- **SwiftData persistence** — Notification history and saved devices survive app restarts
- **HSplitView layout** — Payload editor (left) + send controls (right), responsive at any window size
- **Send button pinned** — Always visible regardless of scroll position
- **Smart quote prevention** — Disabled at OS level + real-time auto-replacement

## How It Works

| Platform | Under the hood |
|---|---|
| **iOS Simulator** | `xcrun simctl push <UDID> <bundle-id> payload.json` |
| **Android Emulator** | `adb -s <serial> shell cmd notification post -S bigtext -t "Title" "tag" "Body"` |
| **Desktop/Web** | `osascript -e 'tell application id "<bundle-id>" to display notification "body" with title "title"'` |

PushForge handles device discovery, UDID/serial lookup, JSON validation, temp file management, payload parsing, and error reporting — so you don't have to.

## Roadmap

- [x] **v0.1** — iOS Simulator push with payload composer
- [x] **v0.2** — Android Emulator push via ADB
- [x] **v0.3** — Desktop/Web notifications via macOS Notification Center
- [x] **v0.4** — Smart JSON diagnostics with auto-fix
- [x] **v0.5** — Multi-platform bundle ID picker with 40+ apps
- [ ] **v0.6** — APNs push to real iOS devices (.p8 token-based auth)
- [ ] **v0.7** — FCM push to real Android devices (service account)
- [ ] **v0.8** — Rich notification preview (mock rendering)
- [ ] **v0.9** — Import/export notification collections
- [ ] **v1.0** — CLI companion (`pushforge send --template welcome.json`) + Homebrew cask

## Common Bundle IDs

<details>
<summary><strong>iOS Simulator</strong> (15 apps)</summary>

| App | Bundle ID |
|---|---|
| Settings | `com.apple.Preferences` |
| Safari | `com.apple.mobilesafari` |
| Messages | `com.apple.MobileSMS` |
| Maps | `com.apple.Maps` |
| Calendar | `com.apple.mobilecal` |
| Photos | `com.apple.mobileslideshow` |
| Notes | `com.apple.mobilenotes` |
| Contacts | `com.apple.MobileAddressBook` |
| Reminders | `com.apple.reminders` |
| Clock | `com.apple.mobiletimer` |
| Weather | `com.apple.weather` |
| Files | `com.apple.DocumentsApp` |
| Camera | `com.apple.camera` |
| Health | `com.apple.Health` |
| Microsoft Teams | `com.microsoft.skype.teams` |

</details>

<details>
<summary><strong>Android Emulator</strong> (15 apps)</summary>

| App | Bundle ID |
|---|---|
| Settings | `com.android.settings` |
| Contacts | `com.android.contacts` |
| Phone | `com.android.dialer` |
| Messages | `com.android.messaging` |
| Calendar | `com.android.calendar` |
| Camera | `com.android.camera2` |
| Gallery | `com.android.gallery3d` |
| Chrome | `com.android.chrome` |
| Gmail | `com.google.android.gm` |
| Google Maps | `com.google.android.apps.maps` |
| YouTube | `com.google.android.youtube` |
| Play Store | `com.android.vending` |
| Clock | `com.google.android.deskclock` |
| Calculator | `com.google.android.calculator` |
| Microsoft Teams | `com.microsoft.teams` |

</details>

<details>
<summary><strong>Desktop/Web</strong> (15 apps)</summary>

| App | Bundle ID |
|---|---|
| Safari | `com.apple.Safari` |
| Mail | `com.apple.mail` |
| Messages | `com.apple.MobileSMS` |
| Calendar | `com.apple.iCal` |
| Notes | `com.apple.Notes` |
| Reminders | `com.apple.reminders` |
| Maps | `com.apple.Maps` |
| Finder | `com.apple.finder` |
| Music | `com.apple.Music` |
| News | `com.apple.news` |
| Slack | `com.tinyspeck.slackmacgap` |
| Microsoft Teams | `com.microsoft.teams2` |
| Chrome | `com.google.Chrome` |
| Firefox | `org.mozilla.firefox` |
| VS Code | `com.microsoft.VSCode` |

</details>

## Contributing

Contributions are welcome! PushForge is built with SwiftUI — if you're a mobile developer, you already know the stack.

```bash
# Fork the repo, then:
git clone https://github.com/YOUR_USERNAME/PushForge.git
cd PushForge
xcodegen generate
open PushForge.xcodeproj
```

**Good first issues:**
- Improve JSON editor with syntax highlighting
- Add dark mode-aware notification preview
- Homebrew cask formula
- APNs real device support (.p8 auth)

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>If PushForge saves you time, give it a &#11088;!</strong><br/><br/>
  <a href="https://github.com/VikrantSingh01/PushForge">
    <img src="https://img.shields.io/badge/%E2%AD%90_Star_PushForge-on_GitHub-blue?style=for-the-badge&logo=github" alt="Star PushForge on GitHub"/>
  </a>
  <br/><br/>
  <a href="https://github.com/VikrantSingh01/PushForge/stargazers">
    <img src="https://img.shields.io/github/stars/VikrantSingh01/PushForge?style=social" alt="GitHub Stars"/>
  </a>
</p>
