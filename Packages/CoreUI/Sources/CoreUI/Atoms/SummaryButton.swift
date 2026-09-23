import SwiftUI

public struct SummaryButton<Label: View>: View {
    private let action: () -> Void
    private let label: Label

    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(SummaryButtonStyle())
    }
}

private struct SummaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        SummaryButtonFace(isPressed: configuration.isPressed, isEnabled: isEnabled) {
            configuration.label
        }
    }
}

private struct SummaryButtonFace<Label: View>: View {
    let isPressed: Bool
    let isEnabled: Bool
    @ViewBuilder let label: Label

    var body: some View {
        label
            .foregroundStyle(isEnabled ? Palette.textSecondary : Palette.textTertiary)
            .background(isPressed ? Palette.surface1 : Palette.background, in: RoundedRectangle(cornerRadius: Radius.xs))
    }
}

private struct SummaryPreviewLabel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(verbatim: "Gastado este mes")
                .font(Typography.caption)
            Text(verbatim: "S/ 1,842.50")
                .font(Typography.amountRow)
        }
    }
}

#Preview("Rest") {
    SummaryButton(action: {}) {
        SummaryPreviewLabel()
    }
    .padding(Spacing.s4)
    .background(Palette.background)
}

#Preview("Pressed") {
    SummaryButtonFace(isPressed: true, isEnabled: true) {
        SummaryPreviewLabel()
            .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget, alignment: .leading)
    }
    .padding(Spacing.s4)
    .background(Palette.background)
}

#Preview("Disabled") {
    SummaryButton(action: {}) {
        SummaryPreviewLabel()
    }
    .disabled(true)
    .padding(Spacing.s4)
    .background(Palette.background)
}
