import SwiftUI

struct AndroidEmulatorPickerView: View {
    let emulators: [AndroidEmulator]
    @Binding var selected: AndroidEmulator?
    let isRefreshing: Bool
    let adbAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !adbAvailable {
                VStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("ADB not found")
                        .font(.caption.weight(.medium))
                    Text("Install Android Studio or add ADB to your PATH")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else if isRefreshing && emulators.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Scanning emulators...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if emulators.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "apps.iphone")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No running Android emulators")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Start an emulator from Android Studio")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                Picker("Emulator", selection: $selected) {
                    ForEach(emulators) { emu in
                        Text(emu.name)
                            .tag(Optional(emu))
                    }
                }
                .labelsHidden()
            }
        }
    }
}
