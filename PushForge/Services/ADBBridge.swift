import Foundation
import os

struct AndroidEmulator: Identifiable, Hashable, Sendable {
    let id: String       // e.g. "emulator-5554"
    let name: String     // e.g. "Pixel_7_API_34" or the serial
    let state: State

    enum State: String, Sendable {
        case online = "device"
        case offline = "offline"
    }

    var isOnline: Bool { state == .online }
}

enum ADBError: LocalizedError {
    case adbNotFound
    case listFailed(String)
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .adbNotFound:
            "ADB not found. Install Android Studio or set ANDROID_HOME."
        case .listFailed(let msg):
            "Failed to list emulators: \(msg)"
        case .sendFailed(let msg):
            "Failed to send notification: \(msg)"
        }
    }
}

actor ADBBridge {
    private let logger = Logger(subsystem: "com.pushforge.app", category: "ADBBridge")

    // MARK: - Find ADB Path

    private func adbPath() async -> String? {
        // Check common locations
        let candidates = [
            "/usr/local/bin/adb",
            "/opt/homebrew/bin/adb",
            "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/adb",
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        // Try which
        if let result = try? await ShellExecutor.run(
            executablePath: "/usr/bin/which",
            arguments: ["adb"]
        ), result.succeeded {
            let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty { return path }
        }
        return nil
    }

    // MARK: - List Emulators

    func listEmulators() async throws -> [AndroidEmulator] {
        guard let adb = await adbPath() else {
            logger.warning("ADB not found on this system")
            throw ADBError.adbNotFound
        }

        let result = try await ShellExecutor.run(
            executablePath: adb,
            arguments: ["devices"]
        )

        guard result.succeeded else {
            throw ADBError.listFailed(result.stderr)
        }

        var emulators: [AndroidEmulator] = []
        let lines = result.stdout.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Lines look like: "emulator-5554	device" or "emulator-5556	offline"
            guard trimmed.hasPrefix("emulator-") else { continue }

            let parts = trimmed.split(separator: "\t", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let serial = String(parts[0])
            let stateStr = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let state: AndroidEmulator.State = stateStr == "device" ? .online : .offline

            // Try to get a friendly name via emu avd name
            let name = await getEmulatorName(adb: adb, serial: serial) ?? serial

            emulators.append(AndroidEmulator(
                id: serial, name: name, state: state
            ))
        }

        logger.info("Found \(emulators.count) Android emulators (\(emulators.filter(\.isOnline).count) online)")
        return emulators
    }

    private func getEmulatorName(adb: String, serial: String) async -> String? {
        guard let result = try? await ShellExecutor.run(
            executablePath: adb,
            arguments: ["-s", serial, "emu", "avd", "name"]
        ), result.succeeded else {
            return nil
        }
        let name = result.stdout.components(separatedBy: "\n").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name?.isEmpty == false ? name : nil
    }

    // MARK: - List Installed Packages

    func listInstalledPackages(serial: String) async -> [DiscoveredApp] {
        guard let adb = await adbPath() else { return [] }

        // Query packages that have a launcher activity — these are the apps
        // visible in the app drawer, not internal overlays or framework components.
        guard let result = try? await ShellExecutor.run(
            executablePath: adb,
            arguments: ["-s", serial, "shell",
                        "cmd", "package", "query-activities",
                        "-a", "android.intent.action.MAIN",
                        "-c", "android.intent.category.LAUNCHER"]
        ), result.succeeded else { return [] }

        // Extract unique package names from "packageName=..." lines
        var seen = Set<String>()
        var apps: [DiscoveredApp] = []
        for line in result.stdout.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("packageName=") else { continue }
            let packageID = String(trimmed.dropFirst("packageName=".count))
            guard !packageID.isEmpty, seen.insert(packageID).inserted else { continue }

            apps.append(DiscoveredApp(
                name: Self.displayName(for: packageID),
                bundleID: packageID
            ))
        }

        logger.info("Discovered \(apps.count) launchable apps on Android emulator \(serial)")
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Derives a human-readable name from an Android package ID.
    private static func displayName(for packageID: String) -> String {
        // Well-known package names
        let knownNames: [String: String] = [
            "com.android.camera2": "Camera",
            "com.android.chrome": "Chrome",
            "com.android.settings": "Settings",
            "com.android.vending": "Play Store",
            "com.android.stk": "SIM Toolkit",
            "com.google.android.gm": "Gmail",
            "com.google.android.apps.maps": "Maps",
            "com.google.android.apps.messaging": "Messages",
            "com.google.android.apps.photos": "Photos",
            "com.google.android.apps.docs": "Drive",
            "com.google.android.apps.safetyhub": "Safety",
            "com.google.android.apps.youtube.music": "YouTube Music",
            "com.google.android.calendar": "Calendar",
            "com.google.android.contacts": "Contacts",
            "com.google.android.deskclock": "Clock",
            "com.google.android.dialer": "Phone",
            "com.google.android.documentsui": "Files",
            "com.google.android.googlequicksearchbox": "Google",
            "com.google.android.youtube": "YouTube",
            "com.google.android.apps.accessibility.voiceaccess": "Voice Access",
        ]

        if let known = knownNames[packageID] { return known }

        // Fall back to last segment, cleaned up
        let lastSegment = packageID.components(separatedBy: ".").last ?? packageID
        return lastSegment
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .prefix(1).uppercased() + lastSegment.dropFirst()
    }

    // MARK: - Send Notification

    /// Posts a notification to the Android emulator's notification shade.
    /// Uses `adb shell cmd notification post` (Android 11+ / API 30+).
    func sendNotification(
        serial: String,
        title: String,
        body: String,
        tag: String = "pushforge"
    ) async throws {
        guard let adb = await adbPath() else {
            throw ADBError.adbNotFound
        }

        // Build shell command as a single string with proper quoting.
        // adb shell passes everything after "shell" to the device's sh,
        // so arguments with spaces must be quoted inside the command string.
        let shellCmd = "cmd notification post -S bigtext -t '\(shellEscape(title))' '\(shellEscape(tag))' '\(shellEscape(body))'"

        let result = try await ShellExecutor.run(
            executablePath: adb,
            arguments: ["-s", serial, "shell", shellCmd]
        )

        guard result.succeeded else {
            let errorMsg = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if errorMsg.isEmpty {
                let stdoutMsg = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                let msg = stdoutMsg.isEmpty ? "Unknown error (exit code \(result.exitCode))" : stdoutMsg
                logger.error("ADB notification failed for \(serial): \(msg)")
                throw ADBError.sendFailed(msg)
            }
            logger.error("ADB notification failed for \(serial): \(errorMsg)")
            throw ADBError.sendFailed(errorMsg)
        }
        logger.info("Notification sent to Android emulator \(serial)")
    }

    // MARK: - Parse APNs-style payload for Android

    /// Extracts title and body from an APNs-style JSON payload for Android display.
    /// Also handles FCM-style payloads with `notification.title` / `notification.body`.
    static func extractTitleBody(from jsonString: String) -> (title: String, body: String)? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Try APNs format: aps.alert.title / aps.alert.body
        if let aps = json["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                let title = alert["title"] as? String ?? "PushForge"
                let body = alert["body"] as? String ?? ""
                return (title, body)
            }
            if let alertString = aps["alert"] as? String {
                return ("PushForge", alertString)
            }
        }

        // Try FCM format: notification.title / notification.body
        if let notification = json["notification"] as? [String: Any] {
            let title = notification["title"] as? String ?? "PushForge"
            let body = notification["body"] as? String ?? ""
            return (title, body)
        }

        // Try top-level title/body (Web Push format)
        if let title = json["title"] as? String {
            let body = json["body"] as? String ?? ""
            return (title, body)
        }

        // Data-only payload — summarize as notification
        if let dataDict = json["data"] as? [String: Any] {
            let action = dataDict["action"] as? String
                ?? dataDict["type"] as? String
                ?? "Data Message"
            let fields = dataDict.keys.sorted().joined(separator: ", ")
            return ("Data: \(action)", "Fields: \(fields)")
        }

        return nil
    }

    /// Escape a string for use inside single quotes in a shell command.
    private func shellEscape(_ text: String) -> String {
        // Replace single quotes with '\'' (end quote, escaped quote, start quote)
        text.replacingOccurrences(of: "'", with: "'\\''")
    }
}
