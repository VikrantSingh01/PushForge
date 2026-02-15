import SwiftUI

struct TemplatePickerView: View {
    let templates: [PayloadTemplate]
    let selected: PayloadTemplate?
    let onSelect: (PayloadTemplate) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(templates) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.caption.weight(.semibold))
                            Text(template.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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
