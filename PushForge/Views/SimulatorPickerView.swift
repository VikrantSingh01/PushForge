import SwiftUI

struct SimulatorPickerView: View {
    let simulators: [BootedSimulator]
    @Binding var selected: BootedSimulator?
    let isRefreshing: Bool

    var body: some View {
        if simulators.isEmpty {
            if isRefreshing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Scanning simulators...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "iphone.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No booted simulators")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Open Simulator.app and boot a device")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        } else {
            Picker("Simulator", selection: $selected) {
                ForEach(simulators) { sim in
                    Text("\(sim.name) (\(sim.runtime))")
                        .tag(Optional(sim))
                }
            }
            .labelsHidden()
        }
    }
}
