import Foundation
import os

/// JSON file structure for external template files.
private struct TemplateFile: Decodable {
    let id: String
    let name: String
    let description: String
    let category: String
    let payload: AnyCodable
}

/// Wrapper to decode arbitrary JSON values.
private struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = NSNull()
        }
    }
}

enum TemplateManager {
    private static let logger = Logger(subsystem: "com.pushforge.app", category: "TemplateManager")

    /// Loads all templates: bundled (from app Resources) + user-added (from Application Support).
    /// User templates with the same ID override bundled ones.
    static func loadBuiltInTemplates() -> [PayloadTemplate] {
        var templates: [PayloadTemplate] = []

        // 1. Load from app bundle (Resources/Templates/ios, android, web)
        templates += loadFromBundle()

        // 2. Load from user directory (~/Library/Application Support/PushForge/Templates/)
        templates += loadFromUserDirectory()

        // Deduplicate by ID — user templates override bundled ones
        var seen = Set<String>()
        var unique: [PayloadTemplate] = []
        for template in templates.reversed() {
            if seen.insert(template.id).inserted {
                unique.append(template)
            }
        }
        return unique.reversed()
    }

    /// User template directory. Drop .json files here to add custom templates.
    static var userTemplateDirectory: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("PushForge/Templates", isDirectory: true)
        }
        let dir = appSupport.appendingPathComponent("PushForge/Templates", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Bundle Loading

    private static func loadFromBundle() -> [PayloadTemplate] {
        guard let resourceURL = Bundle.main.resourceURL else { return [] }
        let templatesDir = resourceURL.appendingPathComponent("Templates", isDirectory: true)
        return loadTemplatesFrom(directory: templatesDir, recursive: true)
    }

    // MARK: - User Directory Loading

    private static func loadFromUserDirectory() -> [PayloadTemplate] {
        loadTemplatesFrom(directory: userTemplateDirectory, recursive: true)
    }

    // MARK: - File Loading

    private static func loadTemplatesFrom(directory url: URL, recursive: Bool = false) -> [PayloadTemplate] {
        let fm = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = recursive ? [] : [.skipsSubdirectoryDescendants]
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: options) else {
            return []
        }

        var templates: [PayloadTemplate] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "json" {
            if let template = loadTemplate(from: fileURL) {
                templates.append(template)
            }
        }
        return templates
    }

    private static func loadTemplate(from url: URL) -> PayloadTemplate? {
        guard let data = try? Data(contentsOf: url) else {
            logger.error("Failed to read template file: \(url.lastPathComponent)")
            return nil
        }

        do {
            let file = try JSONDecoder().decode(TemplateFile.self, from: data)

            // Re-serialize payload to pretty-printed JSON string
            guard JSONSerialization.isValidJSONObject(file.payload.value) else {
                logger.error("Invalid JSON payload in template: \(url.lastPathComponent)")
                return nil
            }
            let payloadData = try JSONSerialization.data(
                withJSONObject: file.payload.value,
                options: [.prettyPrinted, .sortedKeys]
            )
            guard let payloadString = String(data: payloadData, encoding: .utf8) else { return nil }

            let category = PayloadTemplate.Category(rawValue: file.category) ?? .alert

            // Infer platform from parent directory name
            let platform = inferPlatform(from: url, category: file.category)

            return PayloadTemplate(
                id: file.id,
                name: file.name,
                description: file.description,
                category: category,
                platform: platform,
                payload: payloadString
            )
        } catch {
            logger.error("Failed to decode template \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private static func inferPlatform(from url: URL, category: String) -> PayloadTemplate.Platform {
        let pathComponents = url.pathComponents
        if pathComponents.contains("android") { return .android }
        if pathComponents.contains("web") { return .web }
        if pathComponents.contains("ios") { return .ios }
        // Fallback: legacy category-based detection
        if category == "android" { return .android }
        if category == "web" { return .web }
        return .ios
    }
}
