import SwiftUI

public struct Keypad: View {
    private let onKey: (KeypadKey) -> Void

    public init(onKey: @escaping (KeypadKey) -> Void) {
        self.onKey = onKey
    }

    public var body: some View {
        HStack(spacing: Spacing.s2) {
            column([.one, .four, .seven, .toggleSign])
            column([.two, .five, .eight, .zero])
            column([.three, .six, .nine, .decimalSeparator])
            column([.delete])
        }
    }

    private func column(_ keys: [KeypadKey]) -> some View {
        VStack(spacing: Spacing.s2) {
            ForEach(keys, id: \.self) { key in
                Button {
                    onKey(key)
                } label: {
                    KeypadKeyLabel(key: key)
                }
                .buttonStyle(KeypadKeyStyle())
                .accessibilityLabel(Text(verbatim: key.accessibilityLabel))
            }
        }
    }
}

private struct KeypadKeyLabel: View {
    let key: KeypadKey

    var body: some View {
        glyph
            .font(Typography.key)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(minWidth: Spacing.touchTarget, maxWidth: .infinity, minHeight: Spacing.s16, maxHeight: .infinity)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var glyph: some View {
        switch key {
        case .delete:
            Image(systemName: "delete.left")
                .foregroundStyle(.secondary)
        case .toggleSign:
            Image(systemName: "plus.forwardslash.minus")
                .foregroundStyle(.secondary)
        case .decimalSeparator:
            Text(verbatim: ".")
                .foregroundStyle(.primary)
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            Text(verbatim: key.digit.map(String.init) ?? "")
                .foregroundStyle(.primary)
        }
    }
}

private struct KeypadKeyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        KeypadKeyFace(isPressed: configuration.isPressed, isEnabled: isEnabled) {
            configuration.label
        }
    }
}

private struct KeypadKeyFace<Label: View>: View {
    let isPressed: Bool
    let isEnabled: Bool
    @ViewBuilder let label: Label

    var body: some View {
        label
            .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textTertiary, isEnabled ? Palette.textSecondary : Palette.textTertiary)
            .background {
                if isPressed {
                    RoundedRectangle(cornerRadius: Radius.m)
                        .fill(Palette.surface1)
                }
            }
    }
}

#Preview("Rest") {
    Keypad { _ in }
        .frame(maxHeight: .infinity)
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Pressed key") {
    HStack(spacing: Spacing.s2) {
        KeypadKeyFace(isPressed: false, isEnabled: true) { KeypadKeyLabel(key: .seven) }
        KeypadKeyFace(isPressed: true, isEnabled: true) { KeypadKeyLabel(key: .eight) }
        KeypadKeyFace(isPressed: true, isEnabled: true) { KeypadKeyLabel(key: .delete) }
    }
    .frame(height: Spacing.s16)
    .padding(Spacing.s4)
    .background(Palette.background)
}

#Preview("Disabled") {
    Keypad { _ in }
        .disabled(true)
        .frame(maxHeight: .infinity)
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Accessibility size") {
    Keypad { _ in }
        .frame(maxHeight: .infinity)
        .padding(Spacing.s4)
        .background(Palette.background)
        .environment(\.dynamicTypeSize, .accessibility3)
}
