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

    @Test("Missing aps key fails validation")
    func missingApsKey() {
        let json = """
        {
          "notification": {
            "title": "Test"
          }
        }
        """
        let result = PayloadValidator.validate(json)
        if case .missingApsKey = result {
            // Expected
        } else {
            Issue.record("Expected missingApsKey, got \(result)")
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
