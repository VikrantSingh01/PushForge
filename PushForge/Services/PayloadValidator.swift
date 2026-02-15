import Foundation

enum PayloadValidator {
    enum ValidationResult {
        case valid
        case validWithWarning(String, fix: String? = nil)
        case invalidJSON(String, fix: String? = nil)
        case missingApsKey
        case payloadTooLarge(Int)

        var isValid: Bool {
            switch self {
            case .valid, .validWithWarning: return true
            default: return false
            }
        }

        var message: String {
            switch self {
            case .valid:
                "Valid payload"
            case .validWithWarning(let warning, _):
                warning
            case .invalidJSON(let error, _):
                error
            case .missingApsKey:
                "Payload must contain an \"aps\" key"
            case .payloadTooLarge(let size):
                "Payload is \(size) bytes (max \(maxPayloadSize))"
            }
        }

        var fixSuggestion: String? {
            switch self {
            case .invalidJSON(_, let fix): fix
            case .validWithWarning(_, let fix): fix
            default: nil
            }
        }

        var isWarning: Bool {
            if case .validWithWarning = self { return true }
            return false
        }
    }

    static let maxPayloadSize = 4096

    static func validate(_ jsonString: String, targetPlatform: TargetPlatform = .iOSSimulator) -> ValidationResult {
        guard let data = jsonString.data(using: .utf8) else {
            return .invalidJSON("String is not valid UTF-8")
        }

        if data.count > maxPayloadSize {
            return .payloadTooLarge(data.count)
        }

        // Run smart diagnostics before parsing
        if let diagnostic = diagnoseJSONIssues(jsonString) {
            return diagnostic
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data)
            guard let dict = obj as? [String: Any] else {
                return .invalidJSON("Top level must be a JSON object",
                                    fix: "Wrap your payload in { } curly braces")
            }

            // Platform-aware validation
            switch targetPlatform {
            case .iOSSimulator:
                if dict["aps"] == nil {
                    // Check if it looks like an Android or Web payload
                    if dict["notification"] != nil || dict["data"] != nil {
                        return .validWithWarning(
                            "This looks like an Android/FCM payload, but target is iOS Simulator",
                            fix: "Switch to Android Emulator, or use an iOS template with an \"aps\" key."
                        )
                    }
                    if dict["title"] != nil {
                        return .validWithWarning(
                            "This looks like a Web Push payload, but target is iOS Simulator",
                            fix: "Switch to Desktop/Web, or use an iOS template with an \"aps\" key."
                        )
                    }
                    return .missingApsKey
                }

            case .androidEmulator:
                if dict["aps"] != nil {
                    return .validWithWarning(
                        "This looks like an iOS/APNs payload, but target is Android Emulator",
                        fix: "Switch to iOS Simulator, or use an Android template with \"notification\" or \"data\" keys."
                    )
                }

            case .desktop:
                if dict["aps"] != nil {
                    return .validWithWarning(
                        "This looks like an iOS/APNs payload, but target is Desktop/Web",
                        fix: "Switch to iOS Simulator, or use a Web template with top-level \"title\" and \"body\"."
                    )
                }
            }

            return .valid
        } catch {
            let nsError = error as NSError
            let description = extractParseErrorDetail(from: nsError, json: jsonString)
            return .invalidJSON(description.message, fix: description.fix)
        }
    }

    // MARK: - Smart Diagnostics

    private static func diagnoseJSONIssues(_ json: String) -> ValidationResult? {
        // Check for smart/curly quotes
        let smartQuotes: [(Character, String)] = [
            ("\u{201C}", "\u{201C} (left double quote)"),   // "
            ("\u{201D}", "\u{201D} (right double quote)"),  // "
            ("\u{2018}", "\u{2018} (left single quote)"),   // '
            ("\u{2019}", "\u{2019} (right single quote)"),  // '
        ]

        for (char, name) in smartQuotes {
            if let index = json.firstIndex(of: char) {
                let lineCol = lineAndColumn(of: index, in: json)
                return .invalidJSON(
                    "Smart quote \(name) found at line \(lineCol.line), col \(lineCol.col)",
                    fix: "Replace curly/smart quotes with straight quotes (\"). Use Format button to auto-fix after manual replacement."
                )
            }
        }

        // Check for trailing commas before } or ]
        let trailingCommaPattern = ",\\s*[\\]\\}]"
        if let range = json.range(of: trailingCommaPattern, options: .regularExpression) {
            let lineCol = lineAndColumn(of: range.lowerBound, in: json)
            return .invalidJSON(
                "Trailing comma at line \(lineCol.line), col \(lineCol.col)",
                fix: "Remove the comma before the closing } or ]. JSON does not allow trailing commas."
            )
        }

        // Check for single quotes used as string delimiters
        if json.contains("'") {
            // Only flag if it looks like a string delimiter pattern: 'value'
            let singleQuotePattern = "'[^']*'"
            if json.range(of: singleQuotePattern, options: .regularExpression) != nil {
                if let idx = json.firstIndex(of: "'") {
                    let lineCol = lineAndColumn(of: idx, in: json)
                    return .invalidJSON(
                        "Single quote used as string delimiter at line \(lineCol.line), col \(lineCol.col)",
                        fix: "JSON requires double quotes (\") for strings. Replace all single quotes with double quotes."
                    )
                }
            }
        }

        // Check for unescaped control characters in strings
        let lines = json.components(separatedBy: "\n")
        for (lineIndex, line) in lines.enumerated() {
            if line.contains("\t") && !line.contains("\\t") {
                return .invalidJSON(
                    "Unescaped tab character at line \(lineIndex + 1)",
                    fix: "Replace literal tab characters with \\t inside strings."
                )
            }
        }

        return nil
    }

    private static func extractParseErrorDetail(
        from error: NSError,
        json: String
    ) -> (message: String, fix: String?) {
        // NSJSONSerialization embeds byte offset in some error messages
        let desc = error.localizedDescription

        // Try to find character offset from error description
        // Common format: "... around character 42."
        if let range = desc.range(of: "around character (\\d+)", options: .regularExpression) {
            let offsetStr = desc[range].components(separatedBy: " ").last ?? ""
            if let offset = Int(offsetStr) {
                let context = contextAroundOffset(offset, in: json)
                let lineCol = lineAndColumnAtOffset(offset, in: json)
                return (
                    message: "Parse error at line \(lineCol.line), col \(lineCol.col): unexpected character near \"\(context)\"",
                    fix: suggestFixForContext(context, json: json, offset: offset)
                )
            }
        }

        // Try to find line/column from error description
        if let range = desc.range(of: "line (\\d+), column (\\d+)", options: .regularExpression) {
            let match = String(desc[range])
            return (
                message: "Parse error at \(match)",
                fix: "Check for missing commas, extra commas, unmatched brackets, or incorrect quotes near that location."
            )
        }

        // Fallback: provide a generic but helpful message
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ("Payload is empty", fix: "Start with a template from the picker above.")
        }
        if !trimmed.hasPrefix("{") {
            return (
                "JSON must start with {",
                fix: "Wrap your payload in { } curly braces. APNs payloads must be JSON objects."
            )
        }
        if !trimmed.hasSuffix("}") {
            return (
                "JSON appears truncated — missing closing }",
                fix: "Add a closing } at the end of your payload."
            )
        }

        // Count braces/brackets for mismatch
        let openBraces = json.filter { $0 == "{" }.count
        let closeBraces = json.filter { $0 == "}" }.count
        if openBraces != closeBraces {
            return (
                "Mismatched braces: \(openBraces) opening { vs \(closeBraces) closing }",
                fix: openBraces > closeBraces
                    ? "Add \(openBraces - closeBraces) more closing } brace(s)."
                    : "Remove \(closeBraces - openBraces) extra closing } brace(s)."
            )
        }

        let openBrackets = json.filter { $0 == "[" }.count
        let closeBrackets = json.filter { $0 == "]" }.count
        if openBrackets != closeBrackets {
            return (
                "Mismatched brackets: \(openBrackets) opening [ vs \(closeBrackets) closing ]",
                fix: openBrackets > closeBrackets
                    ? "Add \(openBrackets - closeBrackets) more closing ] bracket(s)."
                    : "Remove \(closeBrackets - openBrackets) extra closing ] bracket(s)."
            )
        }

        return (
            "Invalid JSON syntax",
            fix: "Check for: missing commas between key-value pairs, unquoted keys, trailing commas, or smart quotes from copy-paste."
        )
    }

    // MARK: - Helpers

    private static func lineAndColumn(
        of index: String.Index,
        in string: String
    ) -> (line: Int, col: Int) {
        let prefix = string[string.startIndex..<index]
        let lines = prefix.components(separatedBy: "\n")
        return (line: lines.count, col: (lines.last?.count ?? 0) + 1)
    }

    private static func lineAndColumnAtOffset(
        _ offset: Int,
        in string: String
    ) -> (line: Int, col: Int) {
        let data = string.utf8
        let clamped = min(offset, data.count)
        let prefix = String(string.utf8.prefix(clamped)) ?? string
        let lines = prefix.components(separatedBy: "\n")
        return (line: lines.count, col: (lines.last?.count ?? 0) + 1)
    }

    private static func contextAroundOffset(_ offset: Int, in json: String) -> String {
        let bytes = Array(json.utf8)
        let start = max(0, offset - 5)
        let end = min(bytes.count, offset + 10)
        guard start < end else { return "" }
        let slice = bytes[start..<end]
        return String(bytes: slice, encoding: .utf8)?
            .replacingOccurrences(of: "\n", with: "\\n") ?? ""
    }

    private static func suggestFixForContext(_ context: String, json: String, offset: Int) -> String? {
        if context.contains("\"") && context.contains(",") {
            return "Possible missing comma or extra quote near this position. Check that each key-value pair is separated by a comma."
        }
        if context.contains("}") || context.contains("]") {
            return "Check for a trailing comma before the closing brace/bracket, or a missing value."
        }
        return "Check for syntax errors near this position: missing commas, unmatched quotes, or invalid characters."
    }
}

// MARK: - Auto-fix Smart Quotes

extension PayloadValidator {
    /// Replaces common problematic characters (smart quotes, etc.) with JSON-safe equivalents.
    static func autoFixCommonIssues(_ json: String) -> String {
        var fixed = json
        // Replace smart/curly double quotes with straight quotes
        fixed = fixed.replacingOccurrences(of: "\u{201C}", with: "\"") // "
        fixed = fixed.replacingOccurrences(of: "\u{201D}", with: "\"") // "
        // Replace smart/curly single quotes with straight quotes (inside strings)
        fixed = fixed.replacingOccurrences(of: "\u{2018}", with: "'")  // '
        fixed = fixed.replacingOccurrences(of: "\u{2019}", with: "'")  // '
        // Replace em/en dashes that might sneak in from copy-paste
        fixed = fixed.replacingOccurrences(of: "\u{2014}", with: "-")  // —
        fixed = fixed.replacingOccurrences(of: "\u{2013}", with: "-")  // –
        return fixed
    }
}
