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
                .foregroundStyle(Palette.textSecondary)
        case .toggleSign:
            Image(systemName: "plus.forwardslash.minus")
                .foregroundStyle(Palette.textSecondary)
        case .decimalSeparator:
            Text(verbatim: ".")
                .foregroundStyle(Palette.textPrimary)
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            Text(verbatim: key.digit.map(String.init) ?? "")
                .foregroundStyle(Palette.textPrimary)
        }
    }
}

private struct KeypadKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        KeypadKeyFace(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct KeypadKeyFace<Label: View>: View {
    let isPressed: Bool
    @ViewBuilder let label: Label

    var body: some View {
        label
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
        KeypadKeyFace(isPressed: false) { KeypadKeyLabel(key: .seven) }
        KeypadKeyFace(isPressed: true) { KeypadKeyLabel(key: .eight) }
        KeypadKeyFace(isPressed: true) { KeypadKeyLabel(key: .delete) }
    }
    .frame(height: Spacing.s16)
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
