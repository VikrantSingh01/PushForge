# PushForge UI Redesign — Comprehensive AI Prompt

> Use this prompt with Claude Code, GitHub Copilot, or any AI coding assistant.
> Copy everything below the line into your AI tool of choice.

---

## Prompt

You are redesigning the UI of **PushForge**, a native macOS SwiftUI app (macOS 14+, Swift 5) for testing push notifications on iOS Simulators, Android Emulators, and macOS Desktop.

**Tech stack**: SwiftUI, SwiftData, `@Observable` ViewModels, `@Binding` shared state. No external dependencies — use only SwiftUI, AppKit (via `NSViewRepresentable` if needed), and SF Symbols.

### Current Architecture
```
ContentView (HSplitView)
├── PayloadComposerView (left panel)
│   ├── TemplatePickerView — platform tabs + sub-categories + template chips
│   ├── BundleIDPickerView — text field + dropdown menu
│   ├── TextEditor — JSON payload editor
│   └── Validation bar — status + byte counter + fix suggestions
│
└── SendPanelView (right panel)
    ├── Platform segmented picker (iOS Simulator | Android Emulator | Desktop/Web)
    ├── Device picker (SimulatorPickerView or AndroidEmulatorPickerView)
    ├── Saved devices list
    ├── StatusBannerView — idle/sending/success/failure
    └── Send button (pinned to bottom)
```

Templates: 24 external JSON files loaded from `Resources/Templates/{ios,android,web}/`
State: `targetPlatform` and `templatePlatformTab` are synced bidirectionally between panels.

---

### Critical UX Problems to Fix

1. **Wasted space** — Right panel is 50%+ empty white space when no simulator is running
2. **No visual hierarchy** — Everything has equal visual weight, no clear primary action flow
3. **Template UX is weak** — Text-only chips with no icons, color, or platform identity
4. **JSON editor is plain** — No syntax distinction, no line numbers, plain white box
5. **Send button is generic** — Says "Send Push" with no device context
6. **Validation bar is invisible** — Tiny gray text at the bottom, easily missed
7. **No live preview** — Right panel could show what the notification will look like
8. **Empty states are bare** — "No simulators running" is just plain text

---

### Design System

#### Platform Colors (use consistently everywhere)
```
iOS:     .blue    (#007AFF light / #0A84FF dark)
Android: .green   (#34C759 light / #32D74B dark)
Web:     .purple  (#AF52DE light / #BF5AF2 dark)
```

#### Category Icons + Colors (iOS sub-tabs)
```
Basic:    SF Symbol "bell.fill"         tint: .blue
Badge:    SF Symbol "app.badge.fill"    tint: .orange
Silent:   SF Symbol "moon.fill"         tint: .indigo
Rich:     SF Symbol "photo.fill"        tint: .pink
Advanced: SF Symbol "gearshape.2.fill"  tint: .gray
```

#### Platform Icons
```
iOS:     SF Symbol "apple.logo"
Android: SF Symbol "phone.fill"
Web:     SF Symbol "globe"
```

#### Typography
```
Section headers:  .headline + SF Symbol icon
Labels:           .callout.weight(.medium)
Template names:   .caption.weight(.semibold)
Template desc:    .caption2, .secondary
JSON editor:      .system(size: editorFontSize, design: .monospaced)
Validation:       .caption inside pill-shaped background
```

#### Spacing
```
Between major sections:  16pt
Card padding:            10-12pt
Template chip padding:   .horizontal(10), .vertical(8)
Corner radius — cards:   10pt
Corner radius — pills:   12pt
Corner radius — buttons: 8pt
```

---

### Changes to Implement (by file)

#### 1. `TemplatePickerView.swift` — Platform Tabs + Sub-Categories + Chips

**Platform tabs** (iOS / Android / Web):
- Each tab: `HStack { Image(systemName: icon) Text(name) }`
- Selected: platform tint at 15% opacity bg, tinted text+icon, 1px tinted border
- Unselected: `.secondary.opacity(0.06)` bg, `.secondary` text
- `withAnimation(.easeInOut(duration: 0.2))` on switch

**iOS sub-category tabs** (only shown when iOS is selected):
- Each tab: `HStack { Image(systemName: categoryIcon).font(.system(size: 9)) Text(label) }`
- Selected: category tint at 12% bg, tinted text
- Unselected: clear bg, `.secondary` text

**Template chips**:
- Selected border + bg uses the *current platform's tint color* (blue for iOS, green for Android, purple for Web)
- Not the generic `accentColor`

#### 2. `PayloadComposerView.swift` — Editor + Validation + Headers

**Section header "Templates"**:
```swift
HStack(spacing: 6) {
    Image(systemName: "doc.text.fill")
        .foregroundStyle(.secondary)
    Text("Templates")
        .font(.headline)
}
```

**Section header "Payload JSON"**:
```swift
HStack(spacing: 6) {
    Image(systemName: "curlybraces")
        .foregroundStyle(.secondary)
    Text("Payload JSON")
        .fontWeight(.medium)
    Spacer()
    // Format/Minify buttons (style as .bordered .controlSize(.small))
}
```

**JSON editor** — distinguish from other inputs:
```swift
TextEditor(text: $payloadText)
    .font(.system(size: editorFontSize, design: .monospaced))
    .scrollContentBackground(.hidden)
    .padding(8)
    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    .background(Color.accentColor.opacity(0.02))
    .cornerRadius(10)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
    )
```

**Validation bar** — pill-shaped status indicator:
```swift
HStack {
    // Status pill
    HStack(spacing: 4) {
        Image(systemName: validationIcon).font(.caption2)
        Text(validationMessage).font(.caption)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(statusColor.opacity(0.1))
    .foregroundStyle(statusColor)
    .cornerRadius(12)

    Spacer()

    // Payload size with color-coded progress bar
    HStack(spacing: 4) {
        ProgressView(value: min(ratio, 1.0))
            .tint(ratio < 0.5 ? .green : (ratio < 0.8 ? .orange : .red))
            .frame(width: 50)
        Text("\(byteCount) / 4096")
            .font(.caption)
            .foregroundStyle(ratio < 0.5 ? .green : (ratio < 0.8 ? .orange : .red))
    }
}
```

#### 3. `SendPanelView.swift` — Contextual Button + Platform Picker

**Platform picker** — add icons to segmented control:
```swift
Picker("Platform", selection: $viewModel.targetPlatform) {
    Label("iOS", systemImage: "apple.logo").tag(TargetPlatform.iOSSimulator)
    Label("Android", systemImage: "phone.fill").tag(TargetPlatform.androidEmulator)
    Label("Desktop", systemImage: "globe").tag(TargetPlatform.desktop)
}
.pickerStyle(.segmented)
```

**Contextual send button** — show target device name:
```swift
Button {
    // send action
} label: {
    Label(sendButtonLabel, systemImage: "paperplane.fill")
        .frame(maxWidth: .infinity)
}

var sendButtonLabel: String {
    switch targetPlatform {
    case .iOSSimulator:
        viewModel.selectedSimulator.map { "Send to \($0.name)" } ?? "Send Push"
    case .androidEmulator:
        viewModel.selectedAndroidEmulator.map { "Send to \($0.name)" } ?? "Send Push"
    case .desktop:
        "Send to Desktop"
    }
}
```

Also show keyboard shortcut hint below the button:
```swift
Text("Cmd+Return")
    .font(.caption2)
    .foregroundStyle(.tertiary)
    .padding(.top, 2)
```

#### 4. `StatusBannerView.swift` — Animated States

Wrap the entire status view in animation:
```swift
Group {
    switch status {
    case .idle: EmptyView()
    case .sending: // spinner
    case .success: // green banner with .transition(.scale.combined(with: .opacity))
    case .failure: // red banner
    }
}
.animation(.spring(duration: 0.3), value: status)
```

Success state: `.font(.callout.weight(.medium))`, green background at 8%, corner radius 10.
Failure state: red background at 8%, `.textSelection(.enabled)` on error message.

#### 5. `SimulatorPickerView.swift` — Empty State

When no simulators are booted:
```swift
VStack(spacing: 10) {
    Image(systemName: "iphone.slash")
        .font(.system(size: 36))
        .foregroundStyle(.quaternary)
    Text("No simulators running")
        .font(.callout.weight(.medium))
        .foregroundStyle(.secondary)
    Text("Pick one below to boot")
        .font(.caption)
        .foregroundStyle(.tertiary)
}
.frame(maxWidth: .infinity)
.padding(.vertical, 20)
```

#### 6. `ContentView.swift` — Layout Polish

Keep `HSplitView` but improve toolbar:
```swift
ToolbarItem(placement: .navigation) {
    HStack(spacing: 8) {
        Image("PushForgeLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 26, height: 26)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
        Text("PushForge")
            .font(.system(.headline, design: .rounded))
            .fontWeight(.bold)
    }
}
```

---

### Interaction Design

| Element | Hover | Active | Disabled |
|---|---|---|---|
| Platform tab | bg opacity +0.05 | tinted bg + border | N/A |
| Template chip | bg opacity +0.04 | tinted border | N/A |
| Send button | default SwiftUI | spring scale | 50% opacity, gray |
| Format/Minify | underline | pressed | N/A |
| Device boot button | .bordered highlight | spinner | grayed |

### Animation Specs
```
Platform switch:     .easeInOut(duration: 0.2)
Status banner:       .spring(duration: 0.3)
Template selection:  instant (no animation needed)
Device refresh:      spinner while loading
```

---

### Files to Modify
1. `PushForge/Views/TemplatePickerView.swift`
2. `PushForge/Views/PayloadComposerView.swift`
3. `PushForge/Views/SendPanelView.swift`
4. `PushForge/Views/StatusBannerView.swift`
5. `PushForge/Views/SimulatorPickerView.swift`
6. `PushForge/ContentView.swift` (minor toolbar polish)

### DO NOT Modify
- Data models (`Models/`)
- Services (`Services/`)
- ViewModels (`ViewModels/`) — except adding `sendButtonLabel` computed property
- Tests (`PushForgeTests/`)
- Template JSON files (`Resources/Templates/`)

### Constraints
- **SwiftUI only**, macOS 14+ target, no external packages
- Must compile: `SWIFT_VERSION: "5"`, `SWIFT_STRICT_CONCURRENCY: targeted`
- All 18 tests must pass: `xcodebuild -scheme PushForgeTests -destination 'platform=macOS' test`
- Visual changes only — do not alter send logic, validation logic, or state management
- Use SF Symbols (built-in), not custom icons or emoji

---

### Verification Checklist

After implementation, verify:
- [ ] Platform tabs show icons + platform colors (blue/green/purple)
- [ ] iOS sub-categories show distinct icons + category colors
- [ ] Template chips use platform tint (not generic accentColor)
- [ ] Send button says "Send to {device name}" contextually
- [ ] Payload size shows color-coded progress bar
- [ ] Validation status is pill-shaped with colored background
- [ ] JSON editor has subtle tinted background + rounded corners
- [ ] Section headers have SF Symbol icons
- [ ] Status banner animates on state change
- [ ] Empty simulator state has prominent illustration
- [ ] Keyboard shortcut hint shown below send button
- [ ] All 18 tests pass
- [ ] App builds with zero warnings

---

### Future Enhancements (NOT in this PR)
- Live notification preview panel (iOS lockscreen / Android shade mockup)
- Syntax highlighting for JSON (NSViewRepresentable with NSTextView)
- Line numbers in JSON editor
- Dark theme optimizations
- Confetti animation on successful send
- History drawer at bottom instead of sheet
