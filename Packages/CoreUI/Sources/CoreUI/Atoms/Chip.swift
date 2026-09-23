import SwiftUI

public struct Chip: View {
    private let title: String
    private let dot: Color?
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: String, dot: Color? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.dot = dot
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ChipLabel(title: title, dot: dot)
        }
        .buttonStyle(ChipStyle(isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ChipLabel: View {
    let title: String
    let dot: Color?

    var body: some View {
        HStack(spacing: Spacing.s2) {
            if let dot {
                Circle()
                    .fill(dot)
                    .frame(width: Spacing.s2, height: Spacing.s2)
                    .accessibilityHidden(true)
            }
            Text(verbatim: title)
                .font(Typography.label)
        }
        .padding(.horizontal, Spacing.s4)
        .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
        .contentShape(Capsule())
    }
}

private struct ChipStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        ChipFace(isSelected: isSelected, isPressed: configuration.isPressed, isEnabled: isEnabled) {
            configuration.label
        }
    }
}

private struct ChipFace<Label: View>: View {
    let isSelected: Bool
    let isPressed: Bool
    let isEnabled: Bool
    @ViewBuilder let label: Label

    var body: some View {
        label
            .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textTertiary)
            .background {
                if isPressed {
                    Capsule().fill(Palette.surface1)
                }
            }
            .overlay {
                Capsule().strokeBorder(isSelected ? Palette.borderFocus : Palette.border, lineWidth: Spacing.hairline)
            }
    }
}

#Preview("Rest") {
    Chip("Gasto") {}
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Selected") {
    Chip("Efectivo", isSelected: true) {}
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Pressed") {
    ChipFace(isSelected: false, isPressed: true, isEnabled: true) {
        ChipLabel(title: "Gasto", dot: nil)
    }
    .padding(Spacing.s4)
    .background(Palette.background)
}

#Preview("Disabled") {
    Chip("Hoy") {}
        .disabled(true)
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("With dot") {
    Chip("Comida", dot: Palette.categorySage) {}
        .padding(Spacing.s4)
        .background(Palette.background)
}
