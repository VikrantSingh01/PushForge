import SwiftUI
import SwiftData

enum SendStatus: Equatable {
    case idle
    case sending
    case success
    case failure(String)
}

@Observable
class DeviceManagerViewModel {
    var allSimulators: [SimulatorDevice] = []
    var selectedSimulator: SimulatorDevice?
    var isRefreshing = false
    var isBooting = false
    var lastSendStatus: SendStatus = .idle

    private let bridge = SimulatorBridge()

    var bootedSimulators: [SimulatorDevice] {
        allSimulators.filter(\.isBooted)
    }

    var availableSimulators: [SimulatorDevice] {
        allSimulators.filter { !$0.isBooted }
    }

    var canSend: Bool {
        selectedSimulator?.isBooted == true && lastSendStatus != .sending
    }

    func refreshSimulators() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let sims = try await bridge.listAvailableSimulators()
            allSimulators = sims
            if selectedSimulator == nil || !sims.contains(where: { $0.id == selectedSimulator?.id }) {
                selectedSimulator = sims.first(where: \.isBooted) ?? sims.first
            }
        } catch {
            allSimulators = []
            selectedSimulator = nil
        }
    }

    func bootSimulator(_ simulator: SimulatorDevice) async {
        isBooting = true
        defer { isBooting = false }

        do {
            try await bridge.bootSimulator(udid: simulator.id)
            await refreshSimulators()
            selectedSimulator = allSimulators.first(where: { $0.id == simulator.id })
        } catch {
            lastSendStatus = .failure(error.localizedDescription)
        }
    }

    func sendPush(
        payload: String,
        bundleID: String,
        modelContext: ModelContext
    ) async {
        guard let simulator = selectedSimulator else { return }

        lastSendStatus = .sending

        do {
            let result = try await bridge.sendPush(
                udid: simulator.id,
                bundleIdentifier: bundleID,
                payloadJSON: payload
            )

            switch result {
            case .success:
                lastSendStatus = .success
                let record = NotificationRecord(
                    payload: payload,
                    bundleIdentifier: bundleID,
                    deviceLabel: simulator.name,
                    deviceIdentifier: simulator.id,
                    success: true
                )
                modelContext.insert(record)

            case .failure(let msg):
                lastSendStatus = .failure(msg)
                let record = NotificationRecord(
                    payload: payload,
                    bundleIdentifier: bundleID,
                    deviceLabel: simulator.name,
                    deviceIdentifier: simulator.id,
                    success: false,
                    errorMessage: msg
                )
                modelContext.insert(record)
            }
        } catch {
            lastSendStatus = .failure(error.localizedDescription)
        }
    }
}
