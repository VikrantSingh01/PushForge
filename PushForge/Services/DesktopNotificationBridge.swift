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

    /// Sends a macOS desktop notification via osascript.
    /// This mimics how web push notifications appear in macOS Notification Center.
    func sendNotification(
        title: String,
        subtitle: String?,
        body: String,
        soundName: String? = "default"
    ) async throws {
        var script = "display notification \"\(escapeAppleScript(body))\""
        script += " with title \"\(escapeAppleScript(title))\""
        if let subtitle = subtitle, !subtitle.isEmpty {
            script += " subtitle \"\(escapeAppleScript(subtitle))\""
        }
        if let sound = soundName, !sound.isEmpty {
            script += " sound name \"\(escapeAppleScript(sound))\""
        }

        let result = try await shell.run(
            executablePath: "/usr/bin/osascript",
            arguments: ["-e", script]
        )

        guard result.succeeded else {
            let errorMsg = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            throw DesktopNotificationError.sendFailed(errorMsg.isEmpty ? "Unknown error" : errorMsg)
        }
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

    private func escapeAppleScript(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
