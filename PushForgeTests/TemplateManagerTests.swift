import Testing
@testable import PushForge

@Suite("TemplateManager Tests")
struct TemplateManagerTests {

    @Test("Built-in templates load successfully")
    func loadTemplates() {
        let templates = TemplateManager.loadBuiltInTemplates()
        #expect(templates.count == 3)
    }

    @Test("Templates have unique IDs")
    func uniqueIDs() {
        let templates = TemplateManager.loadBuiltInTemplates()
        let ids = Set(templates.map(\.id))
        #expect(ids.count == templates.count)
    }

    @Test("All templates contain valid JSON")
    func validJSON() {
        let templates = TemplateManager.loadBuiltInTemplates()
        for template in templates {
            let result = PayloadValidator.validate(template.payload)
            #expect(result.isValid, "Template '\(template.name)' has invalid payload")
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
