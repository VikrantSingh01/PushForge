import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \NotificationRecord.sentAt, order: .reverse) private var records: [NotificationRecord]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Notification History")
                    .font(.headline)
                Spacer()
                if !records.isEmpty {
                    Button("Clear All") {
                        for record in records {
                            modelContext.delete(record)
                        }
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.borderless)
                }
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            if records.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No notifications sent yet")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(records) { record in
                    HistoryRowView(record: record)
                }
            }
        }
    }
}
