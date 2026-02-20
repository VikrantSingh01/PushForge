import SwiftUI

struct PayloadComposerView: View {
    @Binding var payloadText: String
    @Binding var bundleIdentifier: String
    @Binding var editorFontSize: Double
    @Binding var targetPlatform: TargetPlatform
    @Binding var templatePlatformTab: TemplatePlatformTab
    @Binding var discoveredApps: [DiscoveredApp]
    @State private var viewModel = PayloadComposerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: Templates + Bundle ID (always visible)
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.secondary)
                    Text("Templates")
                        .font(.headline)
                }

                TemplatePickerView(
                    templates: viewModel.templates,
                    selected: viewModel.selectedTemplate,
                    selectedPlatform: $templatePlatformTab,
                    onSelect: { template in
                        viewModel.selectTemplate(template)
                        payloadText = viewModel.payloadText
                    },
                    onPlatformChange: {
                        targetPlatform = templatePlatformTab.targetPlatform
                        viewModel.selectedTemplate = nil
                        payloadText = ""
                        bundleIdentifier = ""
                    }
                )

                Divider()

                BundleIDPickerView(bundleIdentifier: $bundleIdentifier, targetPlatform: targetPlatform, discoveredApps: discoveredApps)

                // Payload header with format/minify
                HStack(spacing: 6) {
                    Image(systemName: "curlybraces")
                        .foregroundStyle(.secondary)
                    Text("Payload JSON")
                        .fontWeight(.medium)
                    Spacer()
                    Button {
                        if let formatted = JSONFormatter.prettyPrint(payloadText) {
                            payloadText = formatted
                        }
                    } label: {
                        Text("Format")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    Button {
                        if let minified = JSONFormatter.minify(payloadText) {
                            payloadText = minified
                        }
                    } label: {
                        Text("Minify")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            .padding([.top, .horizontal])

            // Syntax-highlighted JSON editor
            JSONEditorView(text: $payloadText, fontSize: editorFontSize)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .background(Color.accentColor.opacity(0.02))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 10)
                .onAppear {
                    UserDefaults.standard.set(false, forKey: "NSAutomaticQuoteSubstitutionEnabled")
                    UserDefaults.standard.set(false, forKey: "NSAutomaticDashSubstitutionEnabled")
                }

            // Validation bar — pill status + progress bar
            VStack(alignment: .leading, spacing: 4) {
                let validation = PayloadValidator.validate(payloadText, targetPlatform: targetPlatform)
                let byteCount = payloadText.data(using: .utf8)?.count ?? 0
                let ratio = Double(byteCount) / 4096.0
                let sizeColor: Color = ratio < 0.5 ? .green : (ratio < 0.8 ? .orange : .red)
                let statusColor: Color = validation.isWarning ? .orange : (validation.isValid ? .green : .red)
                let statusIcon = validation.isWarning
                    ? "exclamationmark.triangle.fill"
                    : (validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")

                HStack {
                    // Status pill
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                        Text(validation.message)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.1))
                    .foregroundStyle(statusColor)
                    .cornerRadius(12)

                    Spacer()

                    // Payload size with progress bar
                    HStack(spacing: 4) {
                        ProgressView(value: min(ratio, 1.0))
                            .tint(sizeColor)
                            .frame(width: 50)
                        Text("\(byteCount) / 4096")
                            .font(.caption)
                            .foregroundStyle(sizeColor)
                    }
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
                    .background(Color.orange.opacity(0.06))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .onAppear {
            if payloadText.isEmpty {
                payloadText = viewModel.payloadText
            }
        }
    }
}
