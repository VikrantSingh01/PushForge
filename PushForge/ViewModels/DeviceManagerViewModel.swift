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
    var bootedSimulators: [BootedSimulator] = []
    var selectedSimulator: BootedSimulator?
    var isRefreshing = false
    var lastSendStatus: SendStatus = .idle

    private let bridge = SimulatorBridge()

    var canSend: Bool {
        selectedSimulator != nil && lastSendStatus != .sending
    }

    func refreshSimulators() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let sims = try await bridge.listBootedSimulators()
            bootedSimulators = sims
            // Auto-select first if none selected or current selection is gone
            if selectedSimulator == nil || !sims.contains(where: { $0.id == selectedSimulator?.id }) {
                selectedSimulator = sims.first
            }
        } catch {
            bootedSimulators = []
            selectedSimulator = nil
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
