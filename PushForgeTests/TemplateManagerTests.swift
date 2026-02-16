import Testing
import Foundation
@testable import PushForge

@Suite("TemplateManager Tests")
struct TemplateManagerTests {

    @Test("Built-in templates load successfully")
    func loadTemplates() {
        let templates = TemplateManager.loadBuiltInTemplates()
        #expect(templates.count == 24)
    }

    @Test("Templates have unique IDs")
    func uniqueIDs() {
        let templates = TemplateManager.loadBuiltInTemplates()
        let ids = Set(templates.map(\.id))
        #expect(ids.count == templates.count)
    }

    @Test("All iOS templates contain valid APNs JSON with aps key")
    func validAPNsJSON() {
        let templates = TemplateManager.loadBuiltInTemplates()
            .filter { $0.platform == .ios }
        #expect(!templates.isEmpty)
        for template in templates {
            let result = PayloadValidator.validate(template.payload)
            #expect(result.isValid, "iOS template '\(template.name)' has invalid payload")
        }
    }

    @Test("All Android templates contain valid JSON")
    func validAndroidJSON() {
        let templates = TemplateManager.loadBuiltInTemplates()
            .filter { $0.platform == .android }
        #expect(!templates.isEmpty)
        for template in templates {
            let data = template.payload.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data)
            #expect(json != nil, "Android template '\(template.name)' has invalid JSON")
        }
    }

    @Test("All Web templates contain valid JSON")
    func validWebJSON() {
        let templates = TemplateManager.loadBuiltInTemplates()
            .filter { $0.platform == .web }
        #expect(!templates.isEmpty)
        for template in templates {
            let data = template.payload.data(using: .utf8)!
            let json = try? JSONSerialization.jsonObject(with: data)
            #expect(json != nil, "Web template '\(template.name)' has invalid JSON")
        }
    }

    @Test("All platforms have templates in multiple sub-categories")
    func platformSubCategories() {
        let templates = TemplateManager.loadBuiltInTemplates()
        for platform in PayloadTemplate.Platform.allCases {
            let platformTemplates = templates.filter { $0.platform == platform }
            let categories = Set(platformTemplates.map(\.category))
            #expect(categories.count >= 2, "Platform \(platform.rawValue) should have at least 2 sub-categories, has \(categories.count)")
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
