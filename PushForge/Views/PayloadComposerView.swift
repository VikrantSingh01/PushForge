import SwiftUI

struct PayloadComposerView: View {
    @Binding var payloadText: String
    @Binding var bundleIdentifier: String
    @State private var viewModel = PayloadComposerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Templates")
                .font(.headline)

            TemplatePickerView(
                templates: viewModel.templates,
                selected: viewModel.selectedTemplate
            ) { template in
                viewModel.selectTemplate(template)
                payloadText = viewModel.payloadText
            }

            Divider()

            HStack {
                Text("Bundle ID")
                    .fontWeight(.medium)
                TextField("com.example.myapp", text: $bundleIdentifier)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Payload JSON")
                    .fontWeight(.medium)
                Spacer()
                Button("Format") {
                    if let formatted = JSONFormatter.prettyPrint(payloadText) {
                        payloadText = formatted
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                Button("Minify") {
                    if let minified = JSONFormatter.minify(payloadText) {
                        payloadText = minified
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            TextEditor(text: $payloadText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            // Validation bar
            HStack {
                let validation = PayloadValidator.validate(payloadText)
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(validation.isValid ? .green : .red)
                Text(validation.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let byteCount = payloadText.data(using: .utf8)?.count ?? 0
                Text("\(byteCount) / 4096 bytes")
                    .font(.caption)
                    .foregroundStyle(byteCount > 4096 ? .red : .secondary)
            }
        }
        .padding()
        .onAppear {
            if payloadText.isEmpty {
                payloadText = viewModel.payloadText
            }
        }
    }
}
