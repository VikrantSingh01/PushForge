import SwiftUI

struct HistoryRowView: View {
    let record: NotificationRecord
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(record.payload)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(4)

            if let error = record.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: record.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(record.isSuccess ? .green : .red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.deviceLabel)
                        .font(.callout.weight(.medium))
                    Text(record.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(record.sentAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
