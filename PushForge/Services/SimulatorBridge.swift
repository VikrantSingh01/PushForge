import Foundation

struct BootedSimulator: Identifiable, Hashable, Sendable {
    let id: String       // UDID
    let name: String     // e.g. "iPhone 17 Pro"
    let runtime: String  // e.g. "iOS 26.2"
}

enum SimulatorError: LocalizedError {
    case listFailed(String)
    case parseError(String)
    case invalidPayload(String)

    var errorDescription: String? {
        switch self {
        case .listFailed(let msg): "Failed to list simulators: \(msg)"
        case .parseError(let msg): "Failed to parse simulator data: \(msg)"
        case .invalidPayload(let msg): "Invalid payload: \(msg)"
        }
    }
}

actor SimulatorBridge {
    private let shell = ShellExecutor()

    // MARK: - List Booted Simulators

    func listBootedSimulators() async throws -> [BootedSimulator] {
        let result = try await shell.run(
            arguments: ["simctl", "list", "devices", "booted", "--json"]
        )

        guard result.succeeded else {
            throw SimulatorError.listFailed(result.stderr)
        }

        guard let data = result.stdout.data(using: .utf8) else {
            throw SimulatorError.parseError("Invalid UTF-8 output")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let devicesMap = json?["devices"] as? [String: [[String: Any]]] else {
            throw SimulatorError.parseError("Missing 'devices' key")
        }

        var simulators: [BootedSimulator] = []
        for (runtimeKey, deviceList) in devicesMap {
            let runtimeName = Self.humanReadableRuntime(runtimeKey)
            for device in deviceList {
                guard let udid = device["udid"] as? String,
                      let name = device["name"] as? String,
                      let state = device["state"] as? String,
                      state == "Booted" else { continue }
                simulators.append(BootedSimulator(
                    id: udid, name: name, runtime: runtimeName
                ))
            }
        }
        return simulators
    }

    // MARK: - Send Push Notification

    enum SendResult: Sendable {
        case success
        case failure(String)
    }

    func sendPush(
        udid: String,
        bundleIdentifier: String,
        payloadJSON: String
    ) async throws -> SendResult {
        guard let jsonData = payloadJSON.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: jsonData)) != nil else {
            throw SimulatorError.invalidPayload("Payload is not valid JSON")
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pushforge_\(UUID().uuidString).json")
        try payloadJSON.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = try await shell.run(
            arguments: ["simctl", "push", udid, bundleIdentifier, tempURL.path]
        )

        if result.succeeded {
            return .success
        } else {
            return .failure(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    // MARK: - Helpers

    private static func humanReadableRuntime(_ key: String) -> String {
        // "com.apple.CoreSimulator.SimRuntime.iOS-26-2" -> "iOS 26.2"
        let suffix = key.replacingOccurrences(
            of: "com.apple.CoreSimulator.SimRuntime.", with: ""
        )
        return suffix.replacingOccurrences(of: "-", with: ".")
            .replacingOccurrences(of: "\\.(\\d+)\\.(\\d+)", with: " $1.$2",
                                  options: .regularExpression)
    }
}
