import Foundation
import os

enum DesktopNotificationError: LocalizedError {
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .sendFailed(let msg): "Failed to send desktop notification: \(msg)"
        }
    }
}

actor DesktopNotificationBridge {
    private let logger = Logger(subsystem: "com.pushforge.app", category: "DesktopBridge")

    /// Sends a macOS desktop notification via osascript.
    /// Shows the target app's icon if the app is running; avoids launching apps that aren't.
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

        // Only use `tell application id` if the target app is already running.
        // This shows the app's icon without launching it.
        // If the app isn't running, fall back to a plain notification (avoids launching random apps).
        let script: String
        if !bundleID.isEmpty, await isAppRunning(bundleID: bundleID) {
            script = "tell application id \"\(esc(bundleID))\" to \(notification)"
        } else {
            script = notification
        }

        let result = try await ShellExecutor.run(
            executablePath: "/usr/bin/osascript",
            arguments: ["-e", script]
        )

        guard result.succeeded else {
            let err = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.error("Desktop notification failed: \(err)")
            throw DesktopNotificationError.sendFailed(err.isEmpty ? "Unknown error (exit \(result.exitCode))" : err)
        }
        logger.info("Desktop notification sent: \(title)")
    }

    /// Check if an app is currently running (without launching it).
    private func isAppRunning(bundleID: String) async -> Bool {
        guard let result = try? await ShellExecutor.run(
            executablePath: "/usr/bin/osascript",
            arguments: ["-e", "tell application \"System Events\" to (bundle identifier of processes) contains \"\(esc(bundleID))\""]
        ) else { return false }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    private func esc(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - List Installed macOS Apps

    static func listInstalledApps() -> [DiscoveredApp] {
        var apps: [DiscoveredApp] = []
        let searchPaths = ["/Applications", "/Applications/Utilities"]
        let fm = FileManager.default

        for searchPath in searchPaths {
            guard let contents = try? fm.contentsOfDirectory(atPath: searchPath) else { continue }

            for item in contents where item.hasSuffix(".app") {
                let plistPath = "\(searchPath)/\(item)/Contents/Info.plist"
                guard let plistData = fm.contents(atPath: plistPath),
                      let plist = try? PropertyListSerialization.propertyList(
                          from: plistData, options: [], format: nil
                      ) as? [String: Any],
                      let bundleID = plist["CFBundleIdentifier"] as? String,
                      !bundleID.isEmpty else { continue }

                let displayName = plist["CFBundleDisplayName"] as? String
                    ?? plist["CFBundleName"] as? String
                    ?? item.replacingOccurrences(of: ".app", with: "")
                apps.append(DiscoveredApp(name: displayName, bundleID: bundleID))
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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

        // Data-only payload — summarize as notification
        if let dataDict = json["data"] as? [String: Any] {
            let action = dataDict["action"] as? String
                ?? dataDict["type"] as? String
                ?? "Data Message"
            let fields = dataDict.keys.sorted().joined(separator: ", ")
            return ("Data: \(action)", nil, "Fields: \(fields)")
        }

        return nil
    }

}
