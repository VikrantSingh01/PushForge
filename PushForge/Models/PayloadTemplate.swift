import Foundation

struct PayloadTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: Category
    let payload: String

    enum Category: String, CaseIterable {
        case alert
        case badge
        case silent
        case rich
        case advanced
    }
}
