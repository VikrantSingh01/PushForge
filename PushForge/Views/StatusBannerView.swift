import SwiftUI

struct StatusBannerView: View {
    let status: SendStatus

    var body: some View {
        Group {
            switch status {
            case .idle:
                EmptyView()

            case .sending:
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Sending...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(10)

            case .success:
                Label("Sent successfully!", systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(10)
                    .transition(.scale.combined(with: .opacity))

            case .failure(let message):
                VStack(alignment: .leading, spacing: 4) {
                    Label("Send failed", systemImage: "xmark.circle.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.red.opacity(0.08))
                .cornerRadius(10)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: status)
    }
}
