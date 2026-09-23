import CoreDomain
import SwiftUI

public struct FlatRow: View {
    private let title: String
    private let amount: MoneyText?
    private let isNavigable: Bool
    private let action: () -> Void

    public init(_ title: String, amount: MoneyText? = nil, isNavigable: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.amount = amount
        self.isNavigable = isNavigable
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            FlatRowLabel(title: title, amount: amount, isNavigable: isNavigable)
        }
        .buttonStyle(FlatRowStyle())
    }
}

private struct FlatRowLabel: View {
    let title: String
    let amount: MoneyText?
    let isNavigable: Bool

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Text(verbatim: title)
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
            Spacer(minLength: Spacing.s4)
            if let amount {
                Text(verbatim: amount.text)
                    .font(Typography.amountRow)
                    .foregroundStyle(amount.sign.tint)
                    .accessibilityLabel(Text(verbatim: amount.spokenText))
            }
            if isNavigable {
                Image(systemName: "chevron.right")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, minHeight: Spacing.touchTarget, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct FlatRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FlatRowFace(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct FlatRowFace<Label: View>: View {
    let isPressed: Bool
    @ViewBuilder let label: Label

    var body: some View {
        label
            .background(isPressed ? Palette.surface1 : Palette.background)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Palette.border)
                    .frame(height: Spacing.hairline)
            }
    }
}

#Preview("Rest") {
    FlatRow("Cuentas") {}
        .background(Palette.background)
}

#Preview("Navigable") {
    FlatRow("Reporte", isNavigable: true) {}
        .background(Palette.background)
}

#Preview("With amount") {
    VStack(spacing: 0) {
        FlatRow("Almuerzo", amount: MoneyText((try? Amount(cents: 1_250)) ?? Amount.zero)) {}
        FlatRow("Sueldo", amount: MoneyText((try? Amount(cents: 350_000)) ?? Amount.zero, sign: .positive), isNavigable: true) {}
    }
    .background(Palette.background)
}

#Preview("Pressed") {
    FlatRowFace(isPressed: true) {
        FlatRowLabel(title: "Préstamos", amount: nil, isNavigable: true)
    }
    .background(Palette.background)
}
