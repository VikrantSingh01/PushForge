import SwiftUI

struct PayloadComposerView: View {
    @Binding var payloadText: String
    @Binding var bundleIdentifier: String
    @Binding var editorFontSize: Double
    var targetPlatform: TargetPlatform = .iOSSimulator
    @State private var viewModel = PayloadComposerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: Templates + Bundle ID (always visible)
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

                BundleIDPickerView(bundleIdentifier: $bundleIdentifier, targetPlatform: targetPlatform)

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
            }
            .padding([.top, .horizontal])

            // Middle: TextEditor fills remaining space
            TextEditor(text: $payloadText)
                .font(.system(size: editorFontSize, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .onAppear {
                    // Disable smart quotes system-wide for this app
                    UserDefaults.standard.set(false, forKey: "NSAutomaticQuoteSubstitutionEnabled")
                    UserDefaults.standard.set(false, forKey: "NSAutomaticDashSubstitutionEnabled")
                }
                .onChange(of: payloadText) {
                    // Auto-replace smart quotes as user types
                    let fixed = PayloadValidator.autoFixCommonIssues(payloadText)
                    if fixed != payloadText {
                        payloadText = fixed
                    }
                }

            // Bottom: Validation bar (always visible)
            VStack(alignment: .leading, spacing: 4) {
                let validation = PayloadValidator.validate(payloadText)

                HStack {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(validation.isValid ? .green : .red)
                    Text(validation.message)
                        .font(.caption)
                        .foregroundColor(validation.isValid ? .secondary : .red)
                        .lineLimit(2)
                    Spacer()
                    let byteCount = payloadText.data(using: .utf8)?.count ?? 0
                    Text("\(byteCount) / 4096 bytes")
                        .font(.caption)
                        .foregroundStyle(byteCount > 4096 ? .red : .secondary)
                }

                if let fix = validation.fixSuggestion {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(fix)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Spacer()
                        // Show auto-fix button if smart quotes are detected
                        if payloadText != PayloadValidator.autoFixCommonIssues(payloadText) {
                            Button("Auto-fix") {
                                payloadText = PayloadValidator.autoFixCommonIssues(payloadText)
                            }
                            .font(.caption2)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }
                    .padding(6)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .onAppear {
            if payloadText.isEmpty {
                payloadText = viewModel.payloadText
            }
        }
    }
}
