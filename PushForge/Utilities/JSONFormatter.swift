import Foundation

enum JSONFormatter {
    static func prettyPrint(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let result = String(data: formatted, encoding: .utf8) else {
            return nil
        }
        return result
    }

    static func minify(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: []
              ),
              let result = String(data: formatted, encoding: .utf8) else {
            return nil
        }
        return result
    }
}
