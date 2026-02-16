import Foundation
import SwiftData

@Model
final class SavedDevice {
    var label: String
    var bundleIdentifier: String
    var deviceIdentifier: String
    var deviceType: String  // "simulator" or "realDevice"
    var createdAt: Date
    var lastUsedAt: Date?

    init(
        label: String,
        bundleIdentifier: String,
        deviceIdentifier: String,
        deviceType: String = "simulator",
        createdAt: Date = .now
    ) {
        self.label = label
        self.bundleIdentifier = bundleIdentifier
        self.deviceIdentifier = deviceIdentifier
        self.deviceType = deviceType
        self.createdAt = createdAt
        self.lastUsedAt = createdAt
    }
}
