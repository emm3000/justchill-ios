import SwiftUI

public struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(Typography.label)
                .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Palette.background : Palette.textTertiary)
            .background(fill(isPressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: Radius.m))
    }

    private func fill(isPressed: Bool) -> Color {
        guard isEnabled else { return Palette.surface1 }
        return isPressed ? Palette.textSecondary : Palette.textPrimary
    }
}

#Preview {
    VStack(spacing: Spacing.s4) {
        PrimaryButton("Guardar") {}
        PrimaryButton("Guardar") {}
            .disabled(true)
    }
    .padding(Spacing.s4)
    .background(Palette.background)
}
