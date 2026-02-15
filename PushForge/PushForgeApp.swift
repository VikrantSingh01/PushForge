import SwiftUI
import SwiftData
import UserNotifications

/// Allows notifications to appear even when PushForge is in the foreground.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct PushForgeApp: App {
    @AppStorage("editorFontSize") private var editorFontSize: Double = 13
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

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
        }
    }
}
