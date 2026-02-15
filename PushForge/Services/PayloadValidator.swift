import Foundation

enum PayloadValidator {
    enum ValidationResult {
        case valid
        case invalidJSON(String)
        case missingApsKey
        case payloadTooLarge(Int)

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }

        var message: String {
            switch self {
            case .valid:
                "Valid payload"
            case .invalidJSON(let error):
                "Invalid JSON: \(error)"
            case .missingApsKey:
                "Payload must contain an \"aps\" key"
            case .payloadTooLarge(let size):
                "Payload is \(size) bytes (max \(maxPayloadSize))"
            }
        }
    }

    static let maxPayloadSize = 4096

    static func validate(_ jsonString: String) -> ValidationResult {
        guard let data = jsonString.data(using: .utf8) else {
            return .invalidJSON("String is not valid UTF-8")
        }

        if data.count > maxPayloadSize {
            return .payloadTooLarge(data.count)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data)
            guard let dict = obj as? [String: Any] else {
                return .invalidJSON("Top level must be a JSON object")
            }
            guard dict["aps"] != nil else {
                return .missingApsKey
            }
            return .valid
        } catch {
            return .invalidJSON(error.localizedDescription)
        }
    }
}
