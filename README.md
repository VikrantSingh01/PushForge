<p align="center">
  <img src="https://developer.apple.com/assets/elements/icons/push-notifications/push-notifications-96x96_2x.png" width="80" alt="PushForge Icon"/>
</p>

<h1 align="center">PushForge</h1>

<p align="center">
  <strong>The missing push notification tool for iOS developers.</strong><br/>
  Craft, send, and test APNs payloads on iOS Simulators — zero config, zero cost.
</p>

<p align="center">
  <a href="https://developer.apple.com/xcode/"><img src="https://img.shields.io/badge/Xcode-16%2B-blue?logo=xcode&logoColor=white" alt="Xcode 16+"/></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white" alt="macOS 14+"/></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift&logoColor=white" alt="Swift 5.9+"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License"/></a>
  <img src="https://img.shields.io/badge/tests-11%20passing-brightgreen" alt="Tests"/>
</p>

---

## The Problem

Testing push notifications during iOS development is painful:

- Crafting raw APNs JSON by hand is error-prone
- `xcrun simctl push` requires memorizing UDIDs and file paths
- No free, native macOS tool handles the full workflow
- Existing tools are abandoned (Knuff), iOS-only (NWPusher), or paid

**PushForge fixes all of this in a single, native macOS app.**

## Features

**Zero Setup** — Boot simulators, pick a template, hit Send. That's it.

- **Visual Payload Composer** — Edit APNs JSON with live validation, byte counter, and format/minify buttons
- **11 Built-in Templates** — From basic alerts to Live Activities, critical alerts, and background sync
- **One-Click Simulator Boot** — Boot any iOS Simulator directly from PushForge
- **Notification History** — Every sent notification is logged with status, timestamp, and full payload
- **Save Devices** — Label and save simulator + bundle ID combos for quick reuse
- **Auto-Refresh** — Simulator list updates automatically when you switch back to PushForge
- **Keyboard Shortcuts** — `Cmd+Enter` to send, `Cmd+Shift+H` for history
- **Lightweight** — Native SwiftUI, no Electron, no runtime dependencies

## Templates

PushForge ships with **11 ready-to-use templates** organized by category:

| Category | Templates | Key APNs Features |
|---|---|---|
| **Basic** | Basic Alert | `alert.title`, `alert.body`, `alert.subtitle` |
| **Badge** | Badge + Sound | `badge`, `sound` |
| **Silent** | Silent Push, Background Sync | `content-available`, custom sync data |
| **Rich** | Rich Media, Actionable | `mutable-content`, `category` |
| **Advanced** | Long Payload, Grouped Thread, Critical Alert, Live Activity, Time Sensitive | `thread-id`, `interruption-level`, `content-state`, `relevance-score` |

Every template is valid APNs JSON — edit it or use it as-is.

## Quick Start

### Prerequisites

- macOS 14 (Sonoma) or later
- Xcode 16+ with iOS Simulator runtimes installed

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
2. Click **Boot** next to any simulator in the right panel
3. Select a template (e.g., "Basic Alert")
4. Enter a bundle ID: `com.apple.Preferences`
5. Press **Cmd+Enter** or click **Send Push**

The notification appears on the simulator instantly.

### Run Tests

```bash
xcodebuild -project PushForge.xcodeproj -scheme PushForgeTests -destination 'platform=macOS' test
```

All 11 tests should pass: payload validation, template integrity, simulator bridge, and shell execution.

## Architecture

```
PushForge/
├── Models/          SwiftData models (SavedDevice, NotificationRecord, PayloadTemplate)
├── Services/        Core engine (SimulatorBridge, PayloadValidator, TemplateManager)
├── ViewModels/      @Observable state (PayloadComposerVM, DeviceManagerVM)
├── Views/           SwiftUI views (PayloadComposer, SendPanel, History, etc.)
└── Utilities/       ShellExecutor (Process wrapper), JSONFormatter
```

**Key design decisions:**

- **`actor` services** — `SimulatorBridge` and `ShellExecutor` are actors, keeping `xcrun` process execution off the main thread
- **SwiftData persistence** — Notification history and saved devices survive app restarts
- **HSplitView layout** — Payload editor (left) + send controls (right), both responsive at any window size
- **Send button pinned** — Always visible regardless of scroll position

## How It Works

Under the hood, PushForge wraps `xcrun simctl`:

```bash
# List available simulators
xcrun simctl list devices available --json

# Boot a simulator
xcrun simctl boot <UDID>

# Send a push notification
xcrun simctl push <UDID> <bundle-id> payload.json
```

PushForge handles UDID lookup, JSON validation, temp file management, and error reporting — so you don't have to.

## Roadmap

- [x] **v0.1** — Simulator push with payload composer *(you are here)*
- [ ] **v0.2** — APNs push to real devices (.p8 token-based auth)
- [ ] **v0.3** — FCM support for Android
- [ ] **v0.4** — Rich notification preview (mock rendering)
- [ ] **v0.5** — Drag-and-drop .p8 / FCM service account files
- [ ] **v0.6** — Import/export notification collections
- [ ] **v1.0** — CLI companion (`pushforge send --template welcome.json`)

## Common Bundle IDs for Testing

These apps are pre-installed on every iOS Simulator:

| App | Bundle ID |
|---|---|
| Settings | `com.apple.Preferences` |
| Safari | `com.apple.mobilesafari` |
| Messages | `com.apple.MobileSMS` |
| Maps | `com.apple.Maps` |
| Calendar | `com.apple.mobilecal` |
| Notes | `com.apple.mobilenotes` |

## Contributing

Contributions are welcome! PushForge is built with SwiftUI — if you're an iOS developer, you already know the stack.

```bash
# Fork the repo, then:
git clone https://github.com/YOUR_USERNAME/PushForge.git
cd PushForge
xcodegen generate
open PushForge.xcodeproj
```

**Good first issues:**
- Add more built-in templates
- Improve JSON editor with syntax highlighting
- Add dark mode-aware notification preview
- Homebrew cask formula

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>If PushForge saves you time, give it a star!</strong><br/>
  <a href="https://github.com/VikrantSingh01/PushForge/stargazers">
    <img src="https://img.shields.io/github/stars/VikrantSingh01/PushForge?style=social" alt="GitHub Stars"/>
  </a>
</p>
