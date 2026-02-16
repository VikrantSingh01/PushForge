import SwiftUI

enum TemplatePlatformTab: String, CaseIterable {
    case ios = "iOS"
    case android = "Android"
    case web = "Web"

    init(from target: TargetPlatform) {
        switch target {
        case .iOSSimulator: self = .ios
        case .androidEmulator: self = .android
        case .desktop: self = .web
        }
    }

    var targetPlatform: TargetPlatform {
        switch self {
        case .ios: .iOSSimulator
        case .android: .androidEmulator
        case .web: .desktop
        }
    }

    var icon: String {
        switch self {
        case .ios: "apple.logo"
        case .android: "phone.fill"
        case .web: "globe"
        }
    }

    var tint: Color {
        switch self {
        case .ios: .blue
        case .android: .green
        case .web: .purple
        }
    }

    /// Map to PayloadTemplate.Platform for filtering
    var templatePlatform: PayloadTemplate.Platform {
        switch self {
        case .ios: .ios
        case .android: .android
        case .web: .web
        }
    }
}

struct TemplatePickerView: View {
    let templates: [PayloadTemplate]
    let selected: PayloadTemplate?
    @Binding var selectedPlatform: TemplatePlatformTab
    let onSelect: (PayloadTemplate) -> Void
    let onPlatformChange: (() -> Void)?

    @State private var selectedSubCategory: PayloadTemplate.Category? = .alert

    private static let allCategories: [PayloadTemplate.Category] = [.alert, .badge, .silent, .rich, .advanced]

    private static let categoryMeta: [PayloadTemplate.Category: (label: String, icon: String, tint: Color)] = [
        .alert: ("Basic", "bell.fill", .blue),
        .badge: ("Badge", "app.badge.fill", .orange),
        .silent: ("Silent", "moon.fill", .indigo),
        .rich: ("Rich", "photo.fill", .pink),
        .advanced: ("Advanced", "gearshape.2.fill", .gray),
    ]

    /// Templates for the selected platform
    private var platformTemplates: [PayloadTemplate] {
        templates.filter { $0.platform == selectedPlatform.templatePlatform }
    }

    /// Sub-categories that have templates for the current platform
    private var availableCategories: [PayloadTemplate.Category] {
        Self.allCategories.filter { cat in
            platformTemplates.contains { $0.category == cat }
        }
    }

    /// Templates filtered by platform + sub-category
    private var visibleTemplates: [PayloadTemplate] {
        if let sub = selectedSubCategory {
            return platformTemplates.filter { $0.category == sub }
        }
        return platformTemplates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Platform tabs with icons
            HStack(spacing: 6) {
                ForEach(TemplatePlatformTab.allCases, id: \.self) { platform in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPlatform = platform
                            // Auto-select first available sub-category for the new platform
                            let cats = Self.allCategories.filter { cat in
                                templates.filter { $0.platform == platform.templatePlatform }
                                    .contains { $0.category == cat }
                            }
                            selectedSubCategory = cats.first ?? .alert
                        }
                        onPlatformChange?()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: platform.icon)
                                .font(.caption)
                            Text(platform.rawValue)
                                .font(.callout.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            selectedPlatform == platform
                                ? platform.tint.opacity(0.15)
                                : Color.secondary.opacity(0.06)
                        )
                        .foregroundStyle(
                            selectedPlatform == platform ? platform.tint : .secondary
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedPlatform == platform ? platform.tint.opacity(0.3) : .clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Sub-category tabs — shown for ALL platforms
            if availableCategories.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableCategories, id: \.self) { category in
                            if let meta = Self.categoryMeta[category] {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedSubCategory = category
                                    }
                                    onPlatformChange?()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: meta.icon)
                                            .font(.system(size: 9))
                                        Text(meta.label)
                                            .font(.caption.weight(
                                                selectedSubCategory == category ? .semibold : .regular
                                            ))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedSubCategory == category
                                            ? meta.tint.opacity(0.12) : Color.clear
                                    )
                                    .foregroundStyle(
                                        selectedSubCategory == category ? meta.tint : .secondary
                                    )
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Template chips — color-coded by platform
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(visibleTemplates) { template in
                        let isSelected = selected?.id == template.id
                        let chipTint = selectedPlatform.tint

                        Button {
                            onSelect(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(template.name)
                                    .font(.caption.weight(.semibold))
                                Text(template.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                    ? chipTint.opacity(0.12)
                                    : Color.secondary.opacity(0.06)
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? chipTint : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
