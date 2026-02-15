import Testing
import Foundation
@testable import PushForge

@Suite("TemplateManager Tests")
struct TemplateManagerTests {

    @Test("Built-in templates load successfully")
    func loadTemplates() {
        let templates = TemplateManager.loadBuiltInTemplates()
        #expect(templates.count == 16)
    }

    @Test("Templates have unique IDs")
    func uniqueIDs() {
        let templates = TemplateManager.loadBuiltInTemplates()
        let ids = Set(templates.map(\.id))
        #expect(ids.count == templates.count)
    }

    @Test("All APNs templates contain valid JSON with aps key")
    func validAPNsJSON() {
        let templates = TemplateManager.loadBuiltInTemplates()
            .filter { $0.category != .android && $0.category != .web }
        for template in templates {
            let result = PayloadValidator.validate(template.payload)
            #expect(result.isValid, "Template '\(template.name)' has invalid payload")
        }
    }

    @Test("All Android templates contain valid JSON")
    func validAndroidJSON() {
        let templates = TemplateManager.loadBuiltInTemplates()
            .filter { $0.category == .android }
        #expect(!templates.isEmpty)
        for template in templates {
            let data = template.payload.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data)
            #expect(json != nil, "Android template '\(template.name)' has invalid JSON")
        }
    }

    @Test("Basic alert template has correct structure")
    func basicAlertTemplate() {
        let templates = TemplateManager.loadBuiltInTemplates()
        let basicAlert = templates.first { $0.id == "basic_alert" }
        #expect(basicAlert != nil)
        #expect(basicAlert?.category == .alert)
        #expect(basicAlert?.name == "Basic Alert")
    }
}
