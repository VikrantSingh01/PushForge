import SwiftUI
import SwiftData

@main
struct PushForgeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SavedDevice.self, NotificationRecord.self])
    }
}
