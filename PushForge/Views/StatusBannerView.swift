import SwiftUI

struct StatusBannerView: View {
    let status: SendStatus

    var body: some View {
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
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(8)

        case .success:
            Label("Sent successfully!", systemImage: "checkmark.circle.fill")
                .font(.callout)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)

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
            .padding(8)
            .background(Color.red.opacity(0.08))
            .cornerRadius(8)
        }
    }
}
