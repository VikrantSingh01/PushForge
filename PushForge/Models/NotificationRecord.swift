import Foundation
import SwiftData

@Model
final class NotificationRecord {
    var payload: String
    var bundleIdentifier: String
    var deviceLabel: String
    var deviceIdentifier: String
    var statusRaw: String  // "success" or "failure"
    var errorMessage: String?
    var sentAt: Date

    var isSuccess: Bool { statusRaw == "success" }

    init(
        payload: String,
        bundleIdentifier: String,
        deviceLabel: String,
        deviceIdentifier: String,
        success: Bool,
        errorMessage: String? = nil,
        sentAt: Date = .now
    ) {
        self.payload = payload
        self.bundleIdentifier = bundleIdentifier
        self.deviceLabel = deviceLabel
        self.deviceIdentifier = deviceIdentifier
        self.statusRaw = success ? "success" : "failure"
        self.errorMessage = errorMessage
        self.sentAt = sentAt
    }
}
