import SwiftUI

struct ChildPillSelectView: View {
    let children: [ChildProfile]
    @Binding var selection: Set<ID>

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    // Reuse gradients so we don't repeat ourselves
    private let iconGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.7, blue: 1.0),
                 Color(red: 0.88, green: 0.42, blue: 1.0)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private let borderGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.7, blue: 1.0),
                 Color(red: 0.88, green: 0.42, blue: 1.0)],
        startPoint: .leading, endPoint: .trailing
    )

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(Array(children.enumerated()), id: \.element.id) { _, child in
                let isSelected = selection.contains(child.id)
                Button {
                    if isSelected { selection.remove(child.id) } else { selection.insert(child.id) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(
                                isSelected
                                ? AnyShapeStyle(iconGradient)
                                : AnyShapeStyle(Color.secondary)
                            )
                            .font(.system(size: 16, weight: .semibold))

                        Text(child.name)
                            .font(.callout.weight(.medium))
                    }
                    .glassChip(cornerRadius: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected
                                ? AnyShapeStyle(borderGradient)
                                : AnyShapeStyle(Color.white.opacity(0.25)),
                                lineWidth: 1.2
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
