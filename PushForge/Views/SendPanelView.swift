import SwiftUI
import SwiftData

struct SendPanelView: View {
    @Binding var payloadText: String
    @Binding var bundleIdentifier: String
    @Binding var targetPlatform: TargetPlatform
    @Binding var templatePlatformTab: TemplatePlatformTab
    @State private var viewModel = DeviceManagerViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedDevice.lastUsedAt, order: .reverse) private var savedDevices: [SavedDevice]

    @State private var showSaveSheet = false
    @State private var saveLabel = ""

    /// Contextual send button label showing the target device name.
    private var sendButtonLabel: String {
        switch targetPlatform {
        case .iOSSimulator:
            if let name = viewModel.selectedSimulator?.name { return "Send to \(name)" }
        case .androidEmulator:
            if let name = viewModel.selectedAndroidEmulator?.name { return "Send to \(name)" }
        case .desktop:
            return "Send to Desktop"
        }
        return "Send Push"
    }

    /// Computed send-ability that uses the binding's targetPlatform (always in sync)
    /// instead of viewModel.targetPlatform (may lag behind).
    private var canSendNow: Bool {
        guard viewModel.lastSendStatus != .sending else { return false }
        switch targetPlatform {
        case .iOSSimulator:
            return viewModel.selectedSimulator?.isBooted == true && !bundleIdentifier.isEmpty
        case .androidEmulator:
            return viewModel.selectedAndroidEmulator?.isOnline == true
        case .desktop:
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Platform picker
                    Picker("Platform", selection: $viewModel.targetPlatform) {
                        ForEach(TargetPlatform.allCases, id: \.self) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.targetPlatform) {
                        targetPlatform = viewModel.targetPlatform
                        // Sync template tab with send panel platform
                        templatePlatformTab = TemplatePlatformTab(from: viewModel.targetPlatform)
                        bundleIdentifier = ""
                        payloadText = ""
                        Task { await viewModel.refreshDevices() }
                    }

                    // Device picker (platform-specific)
                    if viewModel.targetPlatform == .desktop {
                        GroupBox {
                            HStack(spacing: 8) {
                                Image(systemName: "desktopcomputer")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("macOS Notification Center")
                                        .font(.headline)
                                    Text("Notification will appear on this Mac — same as web push")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(viewModel.targetPlatform == .iOSSimulator ? "Target Simulator" : "Target Emulator")
                                        .font(.headline)
                                    Spacer()
                                    Button {
                                        Task { await viewModel.refreshDevices() }
                                    } label: {
                                        Label("Refresh", systemImage: "arrow.clockwise")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(viewModel.isRefreshing)
                                }

                                switch viewModel.targetPlatform {
                                case .iOSSimulator:
                                    SimulatorPickerView(
                                        bootedSimulators: viewModel.bootedSimulators,
                                        availableSimulators: viewModel.availableSimulators,
                                        selected: $viewModel.selectedSimulator,
                                        isRefreshing: viewModel.isRefreshing,
                                        isBooting: viewModel.isBooting
                                    ) { sim in
                                        Task { await viewModel.bootSimulator(sim) }
                                    }

                                case .androidEmulator:
                                    AndroidEmulatorPickerView(
                                        emulators: viewModel.onlineAndroidEmulators,
                                        selected: $viewModel.selectedAndroidEmulator,
                                        isRefreshing: viewModel.isRefreshing,
                                        adbAvailable: viewModel.adbAvailable
                                    )

                                case .desktop:
                                    EmptyView()
                                }
                            }
                        }
                    }

                    // Saved devices (iOS only for now)
                    if viewModel.targetPlatform == .iOSSimulator && !savedDevices.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Saved Devices")
                                    .font(.headline)

                                ForEach(savedDevices) { device in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(device.label)
                                                .font(.callout.weight(.medium))
                                            Text(device.bundleIdentifier)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button("Use") {
                                            bundleIdentifier = device.bundleIdentifier
                                            if let sim = viewModel.bootedSimulators.first(where: { $0.id == device.deviceIdentifier }) {
                                                viewModel.selectedSimulator = sim
                                            }
                                            device.lastUsedAt = .now
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                        }
                    }

                    // Save current device button
                    if viewModel.targetPlatform == .iOSSimulator,
                       viewModel.selectedSimulator != nil, !bundleIdentifier.isEmpty {
                        Button {
                            saveLabel = viewModel.selectedSimulator?.name ?? ""
                            showSaveSheet = true
                        } label: {
                            Label("Save Current Device", systemImage: "square.and.arrow.down")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding()
            }
            .task {
                await viewModel.refreshDevices()
            }
            .onChange(of: targetPlatform) {
                // Sync viewModel immediately when targetPlatform changes from template picker
                viewModel.targetPlatform = targetPlatform
                viewModel.lastSendStatus = .idle
                Task { await viewModel.refreshDevices() }
            }

            // Pinned bottom: Status + Send button
            VStack(spacing: 10) {
                Divider()

                StatusBannerView(status: viewModel.lastSendStatus)

                Button {
                    Task {
                        await viewModel.sendPush(
                            payload: payloadText,
                            bundleID: bundleIdentifier,
                            modelContext: modelContext
                        )
                    }
                } label: {
                    Label(sendButtonLabel, systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSendNow)
                .keyboardShortcut(.return, modifiers: .command)

                Text("Cmd+Return")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 4)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await viewModel.refreshDevices() }
        }
        .sheet(isPresented: $showSaveSheet) {
            VStack(spacing: 16) {
                Text("Save Device")
                    .font(.headline)
                TextField("Label", text: $saveLabel)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") {
                        showSaveSheet = false
                    }
                    .keyboardShortcut(.cancelAction)
                    Button("Save") {
                        if let sim = viewModel.selectedSimulator {
                            let device = SavedDevice(
                                label: saveLabel,
                                bundleIdentifier: bundleIdentifier,
                                deviceIdentifier: sim.id
                            )
                            modelContext.insert(device)
                        }
                        showSaveSheet = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(saveLabel.isEmpty)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
}
