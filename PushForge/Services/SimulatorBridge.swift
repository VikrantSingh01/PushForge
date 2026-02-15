import Foundation

struct SimulatorDevice: Identifiable, Hashable, Sendable {
    let id: String       // UDID
    let name: String     // e.g. "iPhone 17 Pro"
    let runtime: String  // e.g. "iOS 26.2"
    let state: State

    enum State: String, Sendable {
        case booted = "Booted"
        case shutdown = "Shutdown"
        case other
    }

    var isBooted: Bool { state == .booted }
}

enum SimulatorError: LocalizedError {
    case listFailed(String)
    case parseError(String)
    case invalidPayload(String)
    case bootFailed(String)

    var errorDescription: String? {
        switch self {
        case .listFailed(let msg): "Failed to list simulators: \(msg)"
        case .parseError(let msg): "Failed to parse simulator data: \(msg)"
        case .invalidPayload(let msg): "Invalid payload: \(msg)"
        case .bootFailed(let msg): "Failed to boot simulator: \(msg)"
        }
    }
}

actor SimulatorBridge {
    private let shell = ShellExecutor()

    // MARK: - List All Available Simulators

    func listAvailableSimulators() async throws -> [SimulatorDevice] {
        let result = try await shell.run(
            arguments: ["simctl", "list", "devices", "available", "--json"]
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

        var simulators: [SimulatorDevice] = []
        for (runtimeKey, deviceList) in devicesMap {
            let runtimeName = Self.humanReadableRuntime(runtimeKey)
            for device in deviceList {
                guard let udid = device["udid"] as? String,
                      let name = device["name"] as? String,
                      let stateStr = device["state"] as? String,
                      let isAvailable = device["isAvailable"] as? Bool,
                      isAvailable else { continue }

                let state: SimulatorDevice.State
                switch stateStr {
                case "Booted": state = .booted
                case "Shutdown": state = .shutdown
                default: state = .other
                }

                simulators.append(SimulatorDevice(
                    id: udid, name: name, runtime: runtimeName, state: state
                ))
            }
        }
        // Booted first, then shutdown, sorted by name within each group
        return simulators.sorted { lhs, rhs in
            if lhs.isBooted != rhs.isBooted { return lhs.isBooted }
            return lhs.name < rhs.name
        }
    }

    // MARK: - Boot Simulator

    func bootSimulator(udid: String) async throws {
        let result = try await shell.run(
            arguments: ["simctl", "boot", udid]
        )
        guard result.succeeded else {
            throw SimulatorError.bootFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
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
