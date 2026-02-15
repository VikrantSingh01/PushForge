import SwiftUI

struct TemplatePickerView: View {
    let templates: [PayloadTemplate]
    let selected: PayloadTemplate?
    let onSelect: (PayloadTemplate) -> Void

    @State private var selectedCategory: PayloadTemplate.Category = .alert

    private var filteredTemplates: [PayloadTemplate] {
        templates.filter { $0.category == selectedCategory }
    }

    private static let categoryLabels: [PayloadTemplate.Category: String] = [
        .alert: "Basic",
        .badge: "Badge",
        .silent: "Silent",
        .rich: "Rich",
        .advanced: "Advanced",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category tabs
            HStack(spacing: 4) {
                ForEach(PayloadTemplate.Category.allCases, id: \.self) { category in
                    let count = templates.filter { $0.category == category }.count
                    if count > 0 {
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(Self.categoryLabels[category] ?? category.rawValue.capitalized)
                                .font(.caption.weight(selectedCategory == category ? .semibold : .regular))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    selectedCategory == category
                                        ? Color.accentColor.opacity(0.15)
                                        : Color.clear
                                )
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Template chips for selected category
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filteredTemplates) { template in
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
