import SwiftUI

@Observable
class PayloadComposerViewModel {
    var templates: [PayloadTemplate] = []
    var selectedTemplate: PayloadTemplate?

    var validationResult: PayloadValidator.ValidationResult {
        PayloadValidator.validate(payloadText)
    }

    var validationIcon: String {
        switch validationResult {
        case .valid: "checkmark.circle.fill"
        case .invalidJSON: "xmark.circle.fill"
        case .missingApsKey: "exclamationmark.triangle.fill"
        case .payloadTooLarge: "exclamationmark.triangle.fill"
        }
    }

    var validationColor: Color {
        validationResult.isValid ? .green : .red
    }

    var validationMessage: String {
        validationResult.message
    }

    var payloadByteCount: Int {
        payloadText.data(using: .utf8)?.count ?? 0
    }

    // These are bound from ContentView
    var payloadText: String
    var bundleIdentifier: String

    init(payloadText: Binding<String>? = nil, bundleIdentifier: Binding<String>? = nil) {
        self.payloadText = ""
        self.bundleIdentifier = ""
        templates = TemplateManager.loadBuiltInTemplates()
        if let first = templates.first {
            selectedTemplate = first
            self.payloadText = first.payload
        }
    }

    func selectTemplate(_ template: PayloadTemplate) {
        selectedTemplate = template
        payloadText = template.payload
    }

    func formatJSON() {
        if let formatted = JSONFormatter.prettyPrint(payloadText) {
            payloadText = formatted
        }
    }

    func minifyJSON() {
        if let minified = JSONFormatter.minify(payloadText) {
            payloadText = minified
        }
    }
}
