import SwiftUI

enum TemplatePlatformTab: String, CaseIterable {
    case ios = "iOS"
    case android = "Android"
    case web = "Web"
}

struct TemplatePickerView: View {
    let templates: [PayloadTemplate]
    let selected: PayloadTemplate?
    let onSelect: (PayloadTemplate) -> Void
    let onPlatformChange: (() -> Void)?

    @State private var selectedPlatform: TemplatePlatformTab = .ios
    @State private var selectedSubCategory: PayloadTemplate.Category? = .alert

    init(templates: [PayloadTemplate], selected: PayloadTemplate?,
         onSelect: @escaping (PayloadTemplate) -> Void,
         onPlatformChange: (() -> Void)? = nil) {
        self.templates = templates
        self.selected = selected
        self.onSelect = onSelect
        self.onPlatformChange = onPlatformChange
    }

    private static let iosCategories: [PayloadTemplate.Category] = [.alert, .badge, .silent, .rich, .advanced]
    private static let categoryLabels: [PayloadTemplate.Category: String] = [
        .alert: "Basic", .badge: "Badge", .silent: "Silent", .rich: "Rich", .advanced: "Advanced",
    ]

    private static let platformCategories: [TemplatePlatformTab: [PayloadTemplate.Category]] = [
        .ios: [.alert, .badge, .silent, .rich, .advanced],
        .android: [.android],
        .web: [.web],
    ]

    private var platformTemplates: [PayloadTemplate] {
        let categories = Self.platformCategories[selectedPlatform] ?? []
        return templates.filter { categories.contains($0.category) }
    }

    private var visibleTemplates: [PayloadTemplate] {
        if selectedPlatform == .ios, let sub = selectedSubCategory {
            return platformTemplates.filter { $0.category == sub }
        }
        return platformTemplates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Platform tabs (iOS / Android / Web)
            HStack(spacing: 6) {
                ForEach(TemplatePlatformTab.allCases, id: \.self) { platform in
                    Button {
                        selectedPlatform = platform
                        selectedSubCategory = platform == .ios ? .alert : nil
                        onPlatformChange?()
                    } label: {
                        Text(platform.rawValue)
                            .font(.callout.weight(selectedPlatform == platform ? .bold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedPlatform == platform
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.secondary.opacity(0.06)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // iOS sub-category tabs
            if selectedPlatform == .ios {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Self.iosCategories, id: \.self) { category in
                            let count = templates.filter { $0.category == category }.count
                            if count > 0 {
                                Button {
                                    selectedSubCategory = category
                                    onPlatformChange?()
                                } label: {
                                    Text(Self.categoryLabels[category] ?? category.rawValue)
                                        .font(.caption.weight(selectedSubCategory == category ? .semibold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            selectedSubCategory == category
                                                ? Color.accentColor.opacity(0.12)
                                                : Color.clear
                                        )
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Template chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(visibleTemplates) { template in
                        Button {
                            onSelect(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .font(.caption.weight(.semibold))
                                Text(template.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                selected?.id == template.id
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.secondary.opacity(0.08)
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selected?.id == template.id
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
