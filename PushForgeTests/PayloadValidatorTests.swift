import Testing
@testable import PushForge

@Suite("PayloadValidator Tests")
struct PayloadValidatorTests {

    @Test("Valid payload passes validation")
    func validPayload() {
        let json = """
        {
          "aps": {
            "alert": {
              "title": "Test",
              "body": "Hello"
            }
          }
        }
        """
        let result = PayloadValidator.validate(json)
        #expect(result.isValid)
    }

    @Test("Invalid JSON fails validation")
    func invalidJSON() {
        let result = PayloadValidator.validate("{ not valid json }")
        if case .invalidJSON = result {
            // Expected
        } else {
            Issue.record("Expected invalidJSON, got \(result)")
        }
    }

    @Test("Missing aps key fails validation for iOS target")
    func missingApsKey() {
        let json = """
        {
          "custom": "no aps key here"
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .iOSSimulator)
        if case .missingApsKey = result {
            // Expected
        } else {
            Issue.record("Expected missingApsKey, got \(result)")
        }
    }

    @Test("Android payload warns when target is iOS")
    func androidPayloadOnIOS() {
        let json = """
        {
          "notification": {
            "title": "Test"
          }
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .iOSSimulator)
        if case .validWithWarning = result {
            // Expected — warns about platform mismatch
        } else {
            Issue.record("Expected validWithWarning, got \(result)")
        }
    }

    @Test("iOS payload warns when target is Android")
    func iosPayloadOnAndroid() {
        let json = """
        {
          "aps": {
            "alert": { "title": "Test", "body": "Hello" }
          }
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .androidEmulator)
        if case .validWithWarning = result {
            // Expected
        } else {
            Issue.record("Expected validWithWarning, got \(result)")
        }
    }

    @Test("Web payload warns when target is iOS")
    func webPayloadOnIOS() {
        let json = """
        {
          "title": "Update Available",
          "body": "Click to learn more."
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .iOSSimulator)
        if case .validWithWarning = result {
            // Expected
        } else {
            Issue.record("Expected validWithWarning, got \(result)")
        }
    }

    @Test("Web payload warns when target is Android")
    func webPayloadOnAndroid() {
        let json = """
        {
          "title": "Update Available",
          "body": "Click to learn more."
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .androidEmulator)
        if case .validWithWarning = result {
            // Expected
        } else {
            Issue.record("Expected validWithWarning, got \(result)")
        }
    }

    @Test("Web payload with data key is valid on Desktop target")
    func webPayloadWithDataOnDesktop() {
        let json = """
        {
          "title": "Task Complete",
          "body": "Your research is ready.",
          "icon": "/icons/agent-complete.png",
          "data": {
            "task_id": "task_abc123",
            "agent": "research",
            "url": "/tasks/abc123"
          },
          "actions": [
            {"action": "view", "title": "View Report"}
          ]
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .desktop)
        #expect(result.isValid)
        #expect(!result.isWarning)
    }

    @Test("Web payload with data key warns when target is iOS")
    func webPayloadWithDataOnIOS() {
        let json = """
        {
          "title": "Task Complete",
          "body": "Your research is ready.",
          "data": { "task_id": "task_abc123" }
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .iOSSimulator)
        if case .validWithWarning(let msg, _) = result {
            #expect(msg.contains("Web Push"))
        } else {
            Issue.record("Expected Web Push warning, got \(result)")
        }
    }

    @Test("Web payload with data key warns when target is Android")
    func webPayloadWithDataOnAndroid() {
        let json = """
        {
          "title": "Task Complete",
          "body": "Your research is ready.",
          "data": { "task_id": "task_abc123" }
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .androidEmulator)
        if case .validWithWarning(let msg, _) = result {
            #expect(msg.contains("Web Push"))
        } else {
            Issue.record("Expected Web Push warning, got \(result)")
        }
    }

    @Test("Android payload warns when target is Desktop")
    func androidPayloadOnDesktop() {
        let json = """
        {
          "notification": {
            "title": "Test",
            "body": "Hello"
          }
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .desktop)
        if case .validWithWarning = result {
            // Expected
        } else {
            Issue.record("Expected validWithWarning, got \(result)")
        }
    }

    @Test("iOS payload warns when target is Desktop")
    func iosPayloadOnDesktop() {
        let json = """
        {
          "aps": {
            "alert": { "title": "Test", "body": "Hello" }
          }
        }
        """
        let result = PayloadValidator.validate(json, targetPlatform: .desktop)
        if case .validWithWarning = result {
            // Expected
        } else {
            Issue.record("Expected validWithWarning, got \(result)")
        }
    }

    @Test("Oversized payload fails validation")
    func payloadTooLarge() {
        var json = """
        {
          "aps": {
            "alert": {
              "body": "
        """
        // Generate a string that exceeds 4096 bytes
        json += String(repeating: "A", count: 4100)
        json += """
            "
            }
          }
        }
        """
        let result = PayloadValidator.validate(json)
        if case .payloadTooLarge = result {
            // Expected
        } else {
            Issue.record("Expected payloadTooLarge, got \(result)")
        }
    }

    @Test("Silent push is valid")
    func silentPush() {
        let json = """
        {
          "aps": {
            "content-available": 1
          }
        }
        """
        let result = PayloadValidator.validate(json)
        #expect(result.isValid)
    }
}
