import SwiftUI
import SwiftData
import os

enum SendStatus: Equatable {
    case idle
    case sending
    case success
    case failure(String)
}

enum TargetPlatform: String, CaseIterable {
    case iOSSimulator = "iOS Simulator"
    case androidEmulator = "Android Emulator"
    case desktop = "Desktop/Web"
}

@Observable
class DeviceManagerViewModel {
    private static let logger = Logger(subsystem: "com.pushforge.app", category: "DeviceManager")

    /// Maximum number of history records to keep.
    private static let maxHistoryRecords = 500

    // Platform selection
    var targetPlatform: TargetPlatform = .iOSSimulator

    // iOS Simulator state
    var allSimulators: [SimulatorDevice] = []
    var selectedSimulator: SimulatorDevice?

    // Android Emulator state
    var androidEmulators: [AndroidEmulator] = []
    var selectedAndroidEmulator: AndroidEmulator?
    var adbAvailable = true

    // Shared state
    var isRefreshing = false
    var isBooting = false
    var lastSendStatus: SendStatus = .idle

    private let simulatorBridge = SimulatorBridge()
    private let adbBridge = ADBBridge()
    private let desktopBridge = DesktopNotificationBridge()

    var bootedSimulators: [SimulatorDevice] {
        allSimulators.filter(\.isBooted)
    }

    var availableSimulators: [SimulatorDevice] {
        allSimulators.filter { !$0.isBooted }
    }

    var onlineAndroidEmulators: [AndroidEmulator] {
        androidEmulators.filter(\.isOnline)
    }

    var canSend: Bool {
        guard lastSendStatus != .sending else { return false }
        switch targetPlatform {
        case .iOSSimulator:
            return selectedSimulator?.isBooted == true
        case .androidEmulator:
            return selectedAndroidEmulator?.isOnline == true
        case .desktop:
            return true // Always available — sends to macOS Notification Center
        }
    }

    // MARK: - Refresh

    func refreshDevices() async {
        isRefreshing = true
        defer { isRefreshing = false }

        switch targetPlatform {
        case .iOSSimulator:
            await refreshSimulators()
        case .androidEmulator:
            await refreshAndroidEmulators()
        case .desktop:
            break // No devices to refresh — always available
        }
    }

    private func refreshSimulators() async {
        do {
            let sims = try await simulatorBridge.listAvailableSimulators()
            allSimulators = sims
            if selectedSimulator == nil || !sims.contains(where: { $0.id == selectedSimulator?.id }) {
                selectedSimulator = sims.first(where: \.isBooted) ?? sims.first
            }
        } catch {
            allSimulators = []
            selectedSimulator = nil
        }
    }

    private func refreshAndroidEmulators() async {
        do {
            let emulators = try await adbBridge.listEmulators()
            androidEmulators = emulators
            adbAvailable = true
            if selectedAndroidEmulator == nil || !emulators.contains(where: { $0.id == selectedAndroidEmulator?.id }) {
                selectedAndroidEmulator = emulators.first(where: \.isOnline)
            }
        } catch let adbError as ADBError {
            androidEmulators = []
            selectedAndroidEmulator = nil
            if case .adbNotFound = adbError {
                adbAvailable = false
            }
        } catch {
            androidEmulators = []
            selectedAndroidEmulator = nil
        }
    }

    // MARK: - Boot (iOS only)

    func bootSimulator(_ simulator: SimulatorDevice) async {
        isBooting = true
        defer { isBooting = false }

        do {
            try await simulatorBridge.bootSimulator(udid: simulator.id)
            await refreshSimulators()
            selectedSimulator = allSimulators.first(where: { $0.id == simulator.id })
        } catch {
            lastSendStatus = .failure(error.localizedDescription)
        }
    }

    // MARK: - Send

    func sendPush(
        payload: String,
        bundleID: String,
        modelContext: ModelContext
    ) async {
        lastSendStatus = .sending

        switch targetPlatform {
        case .iOSSimulator:
            await sendToSimulator(payload: payload, bundleID: bundleID, modelContext: modelContext)
        case .androidEmulator:
            await sendToAndroid(payload: payload, bundleID: bundleID, modelContext: modelContext)
        case .desktop:
            await sendToDesktop(payload: payload, bundleID: bundleID, modelContext: modelContext)
        }

        // Safety: if status is still .sending after all paths, reset
        if lastSendStatus == .sending {
            lastSendStatus = .failure("Send did not complete")
        }

        pruneHistory(modelContext: modelContext)
    }

    /// Removes oldest history records when count exceeds the limit.
    private func pruneHistory(modelContext: ModelContext) {
        do {
            let count = try modelContext.fetchCount(FetchDescriptor<NotificationRecord>())
            guard count > Self.maxHistoryRecords else { return }

            let excess = count - Self.maxHistoryRecords
            var fetch = FetchDescriptor<NotificationRecord>(
                sortBy: [SortDescriptor(\.sentAt, order: .forward)]
            )
            fetch.fetchLimit = excess

            let oldRecords = try modelContext.fetch(fetch)
            for record in oldRecords {
                modelContext.delete(record)
            }
            Self.logger.info("Pruned \(excess) old history records (kept \(Self.maxHistoryRecords))")
        } catch {
            Self.logger.error("History pruning failed: \(error.localizedDescription)")
        }
    }

    private func sendToSimulator(
        payload: String,
        bundleID: String,
        modelContext: ModelContext
    ) async {
        guard let simulator = selectedSimulator else {
            lastSendStatus = .failure("No simulator selected")
            return
        }

        do {
            let result = try await simulatorBridge.sendPush(
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

    private func sendToAndroid(
        payload: String,
        bundleID: String,
        modelContext: ModelContext
    ) async {
        guard let emulator = selectedAndroidEmulator else {
            lastSendStatus = .failure("No Android emulator selected")
            return
        }

        // Extract title/body from the JSON payload
        let extracted = ADBBridge.extractTitleBody(from: payload)
        let title = extracted?.title ?? "PushForge"
        let body = extracted?.body ?? payload.prefix(200).description

        do {
            try await adbBridge.sendNotification(
                serial: emulator.id,
                title: title,
                body: body,
                tag: "pushforge-\(Int(Date().timeIntervalSince1970))"
            )
            lastSendStatus = .success
            let record = NotificationRecord(
                payload: payload,
                bundleIdentifier: bundleID,
                deviceLabel: "\(emulator.name) (Android)",
                deviceIdentifier: emulator.id,
                success: true
            )
            modelContext.insert(record)
        } catch {
            lastSendStatus = .failure(error.localizedDescription)
            let record = NotificationRecord(
                payload: payload,
                bundleIdentifier: bundleID,
                deviceLabel: "\(emulator.name) (Android)",
                deviceIdentifier: emulator.id,
                success: false,
                errorMessage: error.localizedDescription
            )
            modelContext.insert(record)
        }
    }

    private func sendToDesktop(
        payload: String,
        bundleID: String,
        modelContext: ModelContext
    ) async {
        let extracted = DesktopNotificationBridge.extractContent(from: payload)
        let title = extracted?.title ?? "PushForge"
        let subtitle = extracted?.subtitle
        let body = extracted?.body ?? payload.prefix(200).description

        do {
            try await desktopBridge.sendNotification(
                title: title,
                subtitle: subtitle,
                body: body,
                bundleID: bundleID
            )
            lastSendStatus = .success
            let record = NotificationRecord(
                payload: payload,
                bundleIdentifier: bundleID,
                deviceLabel: "macOS Desktop",
                deviceIdentifier: "desktop",
                success: true
            )
            modelContext.insert(record)
        } catch {
            lastSendStatus = .failure(error.localizedDescription)
            let record = NotificationRecord(
                payload: payload,
                bundleIdentifier: bundleID,
                deviceLabel: "macOS Desktop",
                deviceIdentifier: "desktop",
                success: false,
                errorMessage: error.localizedDescription
            )
            modelContext.insert(record)
        }
    }
}
