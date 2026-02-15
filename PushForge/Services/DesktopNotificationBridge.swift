import Foundation
import UserNotifications

enum DesktopNotificationError: LocalizedError {
    case sendFailed(String)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .sendFailed(let msg): "Failed to send desktop notification: \(msg)"
        case .permissionDenied: "Notification permission denied. Enable in System Settings > Notifications > PushForge."
        }
    }
}

actor DesktopNotificationBridge {
    private var permissionGranted = false

    /// Sends a macOS desktop notification via UNUserNotificationCenter.
    /// The notification appears with PushForge's app icon.
    func sendNotification(
        title: String,
        subtitle: String?,
        body: String,
        soundName: String? = "default"
    ) async throws {
        // Request permission if not yet granted
        if !permissionGranted {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            if !granted {
                throw DesktopNotificationError.permissionDenied
            }
        }

        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle, !subtitle.isEmpty {
            content.subtitle = subtitle
        }
        content.body = body
        if soundName != nil {
            content.sound = .default
        }

        let identifier = "pushforge-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await UNUserNotificationCenter.current().add(request)
    }

    /// Extracts title, subtitle, and body from JSON payload for desktop display.
    static func extractContent(from jsonString: String) -> (title: String, subtitle: String?, body: String)? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Try APNs format
        if let aps = json["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                let title = alert["title"] as? String ?? "PushForge"
                let subtitle = alert["subtitle"] as? String
                let body = alert["body"] as? String ?? ""
                return (title, subtitle, body)
            }
            if let alertString = aps["alert"] as? String {
                return ("PushForge", nil, alertString)
            }
        }

        // Try FCM/Android format
        if let notification = json["notification"] as? [String: Any] {
            let title = notification["title"] as? String ?? "PushForge"
            let body = notification["body"] as? String ?? ""
            return (title, nil, body)
        }

        // Try Web Push format
        if let title = json["title"] as? String {
            let body = json["body"] as? String ?? ""
            return (title, nil, body)
        }

        return nil
    }

}
