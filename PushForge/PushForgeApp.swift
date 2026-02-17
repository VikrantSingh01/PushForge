import SwiftUI
import SwiftData

extension Notification.Name {
    static let refreshDevices = Notification.Name("PushForgeRefreshDevices")
}

@main
struct PushForgeApp: App {
    @AppStorage("editorFontSize") private var editorFontSize: Double = 13

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SavedDevice.self, NotificationRecord.self])
        .commands {
            CommandGroup(after: .textEditing) {
                Button("Zoom In") {
                    editorFontSize = min(editorFontSize + 1, 32)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    editorFontSize = max(editorFontSize - 1, 9)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Reset Zoom") {
                    editorFontSize = 13
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button("Refresh Devices") {
                    NotificationCenter.default.post(name: .refreshDevices, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
