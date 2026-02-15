import Foundation

enum DesktopNotificationError: LocalizedError {
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .sendFailed(let msg): "Failed to send desktop notification: \(msg)"
        }
    }
}

actor DesktopNotificationBridge {
    private let shell = ShellExecutor()

    /// Sends a macOS desktop notification via osascript, using the target app's icon.
    /// `tell application id "<bundleID>"` makes the notification appear with that app's icon.
    func sendNotification(
        title: String,
        subtitle: String?,
        body: String,
        bundleID: String,
        soundName: String? = "default"
    ) async throws {
        var notification = "display notification \"\(esc(body))\""
        notification += " with title \"\(esc(title))\""
        if let subtitle = subtitle, !subtitle.isEmpty {
            notification += " subtitle \"\(esc(subtitle))\""
        }
        if let sound = soundName, !sound.isEmpty {
            notification += " sound name \"\(esc(sound))\""
        }

        // Use the target app's bundle ID so the notification shows that app's icon.
        // Falls back to PushForge's own identifier if no bundle ID provided.
        let appID = bundleID.isEmpty ? "com.pushforge.app" : bundleID
        let script = "tell application id \"\(esc(appID))\" to \(notification)"

        let result = try await shell.run(
            executablePath: "/usr/bin/osascript",
            arguments: ["-e", script]
        )

        guard result.succeeded else {
            let err = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw DesktopNotificationError.sendFailed(err.isEmpty ? "Unknown error (exit \(result.exitCode))" : err)
        }
    }

    private func esc(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
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
