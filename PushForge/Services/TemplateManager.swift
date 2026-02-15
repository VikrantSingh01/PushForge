import Foundation

enum TemplateManager {
    static func loadBuiltInTemplates() -> [PayloadTemplate] {
        [
            // MARK: - Basic

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

            // MARK: - Rich Media

            PayloadTemplate(
                id: "rich_media",
                name: "Rich Media",
                description: "Image/video via Notification Service Extension",
                category: .rich,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Photo Shared",
                      "body": "Alex shared a photo with you."
                    },
                    "mutable-content": 1,
                    "sound": "default"
                  },
                  "media-url": "https://example.com/photo.jpg",
                  "media-type": "image"
                }
                """
            ),
            PayloadTemplate(
                id: "actionable",
                name: "Actionable",
                description: "Notification with action buttons via category",
                category: .rich,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Friend Request",
                      "body": "Taylor wants to connect with you."
                    },
                    "category": "FRIEND_REQUEST",
                    "sound": "default"
                  },
                  "sender-id": "user-12345"
                }
                """
            ),

            // MARK: - Advanced

            PayloadTemplate(
                id: "long_payload",
                name: "Long Payload",
                description: "Large payload with custom data fields",
                category: .advanced,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Order #8842 Shipped",
                      "subtitle": "Arriving Thursday",
                      "body": "Your order containing 3 items has been shipped via Express Delivery. Track your package for real-time updates on the estimated delivery window.",
                      "title-loc-key": "ORDER_SHIPPED_TITLE",
                      "loc-key": "ORDER_SHIPPED_BODY",
                      "loc-args": ["8842", "3", "Thursday"]
                    },
                    "badge": 1,
                    "sound": {
                      "name": "default",
                      "volume": 0.8
                    },
                    "thread-id": "order-8842",
                    "mutable-content": 1
                  },
                  "order-id": "8842",
                  "tracking-url": "https://example.com/track/8842",
                  "items": [
                    {"name": "Wireless Earbuds", "qty": 1},
                    {"name": "USB-C Cable", "qty": 2}
                  ],
                  "carrier": "Express Delivery",
                  "eta": "2026-02-20T14:00:00Z"
                }
                """
            ),
            PayloadTemplate(
                id: "grouped_thread",
                name: "Grouped Thread",
                description: "Threaded notifications grouped by conversation",
                category: .advanced,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Team Chat",
                      "subtitle": "Jordan",
                      "body": "Hey, the build is passing now! Ready for review."
                    },
                    "thread-id": "chat-team-engineering",
                    "sound": "default"
                  },
                  "chat-id": "team-engineering",
                  "sender": "jordan",
                  "message-id": "msg-99201"
                }
                """
            ),
            PayloadTemplate(
                id: "critical_alert",
                name: "Critical Alert",
                description: "Bypasses Do Not Disturb (requires entitlement)",
                category: .advanced,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Security Alert",
                      "subtitle": "Unusual Sign-In Detected",
                      "body": "A new sign-in to your account was detected from San Francisco, CA. If this wasn't you, secure your account immediately."
                    },
                    "sound": {
                      "critical": 1,
                      "name": "alarm.caf",
                      "volume": 1.0
                    },
                    "interruption-level": "critical"
                  },
                  "alert-type": "security",
                  "login-location": "San Francisco, CA",
                  "login-ip": "203.0.113.42",
                  "timestamp": "2026-02-14T12:30:00Z"
                }
                """
            ),
            PayloadTemplate(
                id: "live_activity",
                name: "Live Activity",
                description: "Update a Live Activity / Dynamic Island",
                category: .advanced,
                payload: """
                {
                  "aps": {
                    "timestamp": 1708000000,
                    "event": "update",
                    "content-state": {
                      "home-score": 3,
                      "away-score": 2,
                      "game-time": "4th Quarter",
                      "time-remaining": "2:45"
                    },
                    "alert": {
                      "title": "Score Update",
                      "body": "Home 3 - 2 Away | 4th Quarter 2:45"
                    }
                  }
                }
                """
            ),
            PayloadTemplate(
                id: "time_sensitive",
                name: "Time Sensitive",
                description: "Breaks through Focus and notification summary",
                category: .advanced,
                payload: """
                {
                  "aps": {
                    "alert": {
                      "title": "Ride Arriving",
                      "body": "Your driver is 2 minutes away. White Tesla Model 3, plate ABC-1234."
                    },
                    "interruption-level": "time-sensitive",
                    "relevance-score": 0.95,
                    "sound": "default"
                  },
                  "ride-id": "ride-7712",
                  "driver": "Sam",
                  "vehicle": "White Tesla Model 3",
                  "eta-seconds": 120
                }
                """
            ),
            PayloadTemplate(
                id: "background_sync",
                name: "Background Sync",
                description: "Silent push with multi-field sync payload",
                category: .silent,
                payload: """
                {
                  "aps": {
                    "content-available": 1
                  },
                  "sync": {
                    "type": "incremental",
                    "collections": ["messages", "contacts", "settings"],
                    "since": "2026-02-14T00:00:00Z",
                    "priority": "high"
                  },
                  "server-timestamp": "2026-02-14T12:00:00Z"
                }
                """
            ),

            // MARK: - Android

            PayloadTemplate(
                id: "android_basic",
                name: "Android Basic",
                description: "Simple notification with title and body",
                category: .android,
                payload: """
                {
                  "notification": {
                    "title": "Hello from PushForge",
                    "body": "This is a test notification for Android."
                  }
                }
                """
            ),
            PayloadTemplate(
                id: "android_data",
                name: "Android Data",
                description: "Data-only message for background handling",
                category: .android,
                payload: """
                {
                  "data": {
                    "action": "sync",
                    "content_id": "12345",
                    "timestamp": "2026-02-14T12:00:00Z"
                  }
                }
                """
            ),
            PayloadTemplate(
                id: "android_rich",
                name: "Android Rich",
                description: "Notification + data with channel and priority",
                category: .android,
                payload: """
                {
                  "notification": {
                    "title": "New Order Received",
                    "body": "Order #4521 from Alex — 3 items, $42.99",
                    "channel_id": "orders",
                    "click_action": "OPEN_ORDER_DETAIL",
                    "icon": "ic_notification",
                    "color": "#FF5722"
                  },
                  "data": {
                    "order_id": "4521",
                    "customer": "Alex",
                    "total": "42.99"
                  }
                }
                """
            ),

            // MARK: - Web / Desktop

            PayloadTemplate(
                id: "web_basic",
                name: "Web Basic",
                description: "Simple web push notification",
                category: .web,
                payload: """
                {
                  "title": "New Update Available",
                  "body": "Version 2.0 is ready — click to learn more.",
                  "icon": "/icons/app-icon-192.png",
                  "badge": "/icons/badge-72.png",
                  "tag": "update-v2"
                }
                """
            ),
            PayloadTemplate(
                id: "web_action",
                name: "Web Actions",
                description: "Web push with action buttons and image",
                category: .web,
                payload: """
                {
                  "title": "Flash Sale Ending Soon",
                  "body": "50% off all items — only 2 hours left!",
                  "icon": "/icons/sale-icon.png",
                  "image": "/images/sale-banner.jpg",
                  "tag": "flash-sale",
                  "requireInteraction": true,
                  "actions": [
                    {"action": "shop", "title": "Shop Now"},
                    {"action": "dismiss", "title": "Maybe Later"}
                  ],
                  "data": {
                    "url": "/sale",
                    "campaign": "flash-sale-feb"
                  }
                }
                """
            ),
        ]
    }
}
