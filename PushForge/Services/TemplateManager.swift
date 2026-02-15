import Foundation

enum TemplateManager {
    static func loadBuiltInTemplates() -> [PayloadTemplate] {
        [
            PayloadTemplate(
                id: "basic_alert",
                name: "Basic Alert",
                description: "Simple title + body alert",
                category: .alert,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Hello from PushForge",
                      "subtitle": "Test Notification",
                      "body": "This is a test push notification sent from PushForge."
                    }
                  }
                }
                """
            ),
            PayloadTemplate(
                id: "badge_sound",
                name: "Badge + Sound",
                description: "Sets badge count and plays default sound",
                category: .badge,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "New Message",
                      "body": "You have a new message waiting."
                    },
                    "badge": 3,
                    "sound": "default"
                  }
                }
                """
            ),
            PayloadTemplate(
                id: "silent_push",
                name: "Silent Push",
                description: "Background content-available push",
                category: .silent,
                payload: """
                {
                  "aps": {
                    "content-available": 1
                  },
                  "custom-key": "background-refresh"
                }
                """
            ),
        ]
    }
}
