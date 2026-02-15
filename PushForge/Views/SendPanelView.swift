import SwiftUI
import SwiftData

struct SendPanelView: View {
    @Binding var payloadText: String
    @Binding var bundleIdentifier: String
    @State private var viewModel = DeviceManagerViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedDevice.lastUsedAt, order: .reverse) private var savedDevices: [SavedDevice]

    @State private var showSaveSheet = false
    @State private var saveLabel = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simulator picker
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Target Simulator")
                            .font(.headline)
                        Spacer()
                        Button {
                            Task {
                                await viewModel.refreshSimulators()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.isRefreshing)
                    }

                    SimulatorPickerView(
                        simulators: viewModel.bootedSimulators,
                        selected: $viewModel.selectedSimulator,
                        isRefreshing: viewModel.isRefreshing
                    )
                }
            }
            .task {
                await viewModel.refreshSimulators()
            }

            // Saved devices
            if !savedDevices.isEmpty {
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
            if viewModel.selectedSimulator != nil && !bundleIdentifier.isEmpty {
                Button {
                    saveLabel = viewModel.selectedSimulator?.name ?? ""
                    showSaveSheet = true
                } label: {
                    Label("Save Current Device", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            // Status + Send
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
                Label("Send Push", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canSend || bundleIdentifier.isEmpty)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await viewModel.refreshSimulators()
            }
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
