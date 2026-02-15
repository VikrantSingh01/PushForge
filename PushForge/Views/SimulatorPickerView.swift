import SwiftUI

struct SimulatorPickerView: View {
    let bootedSimulators: [SimulatorDevice]
    let availableSimulators: [SimulatorDevice]
    @Binding var selected: SimulatorDevice?
    let isRefreshing: Bool
    let isBooting: Bool
    let onBoot: (SimulatorDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isRefreshing && bootedSimulators.isEmpty && availableSimulators.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Scanning simulators...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !bootedSimulators.isEmpty {
                Picker("Simulator", selection: $selected) {
                    ForEach(bootedSimulators) { sim in
                        Text("\(sim.name) (\(sim.runtime))")
                            .tag(Optional(sim))
                    }
                }
                .labelsHidden()
            }

            if bootedSimulators.isEmpty && !availableSimulators.isEmpty {
                Text("No simulators running — pick one to boot:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !availableSimulators.isEmpty {
                DisclosureGroup(bootedSimulators.isEmpty ? "Available Simulators" : "Boot Another Simulator") {
                    ForEach(availableSimulators) { sim in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(sim.name)
                                    .font(.callout)
                                Text(sim.runtime)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button {
                                onBoot(sim)
                            } label: {
                                if isBooting {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                } else {
                                    Text("Boot")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isBooting)
                        }
                    }
                }
                .font(.caption)
            }
        }
    }
}
