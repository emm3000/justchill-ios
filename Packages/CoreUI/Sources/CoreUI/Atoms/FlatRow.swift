import CoreDomain
import SwiftUI

public struct FlatRow: View {
    private let title: String
    private let amount: MoneyText?
    private let isNavigable: Bool
    private let action: (() -> Void)?

    public init(_ title: String, amount: MoneyText? = nil, isNavigable: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.amount = amount
        self.isNavigable = isNavigable
        self.action = action
    }

    public init(_ title: String, amount: MoneyText? = nil) {
        self.title = title
        self.amount = amount
        isNavigable = false
        action = nil
    }

    public var body: some View {
        if let action: () -> Void = action {
            Button(action: action) {
                FlatRowLabel(title: title, amount: amount, isNavigable: isNavigable)
            }
            .buttonStyle(FlatRowStyle())
        } else {
            FlatRowFace(isPressed: false, isEnabled: true) {
                FlatRowLabel(title: title, amount: amount, isNavigable: false)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private struct FlatRowLabel: View {
    let title: String
    let amount: MoneyText?
    let isNavigable: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize

    var body: some View {
        HStack(spacing: Spacing.s4) {
            columns {
                Text(verbatim: title)
                    .font(Typography.body)
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: Spacing.s4)
                }
                if let amount {
                    Text(verbatim: amount.text)
                        .font(Typography.amountRow)
                        .foregroundStyle(amount.sign.tint)
                        .accessibilityLabel(Text(verbatim: amount.spokenText))
                }
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

    private var columns: AnyLayout {
        guard dynamicTypeSize.isAccessibilitySize else { return AnyLayout(HStackLayout(spacing: Spacing.s4)) }
        return AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s1))
    }
}

private struct FlatRowStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        FlatRowFace(isPressed: configuration.isPressed, isEnabled: isEnabled) {
            configuration.label
        }
    }
}

private struct FlatRowFace<Label: View>: View {
    let isPressed: Bool
    let isEnabled: Bool
    @ViewBuilder let label: Label

    var body: some View {
        label
            .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textTertiary)
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

#Preview("Static") {
    VStack(spacing: 0) {
        FlatRow("Almuerzo", amount: MoneyText((try? Amount(cents: 1_250)) ?? Amount.zero))
        FlatRow("Sueldo", amount: MoneyText((try? Amount(cents: 350_000)) ?? Amount.zero, sign: .positive))
        FlatRow("Sin categoría", amount: MoneyText((try? Amount(cents: 800)) ?? Amount.zero))
    }
    .background(Palette.background)
}

#Preview("Accessibility size") {
    VStack(spacing: 0) {
        FlatRow("Sin categoría", amount: MoneyText((try? Amount(cents: 184_250)) ?? Amount.zero))
        FlatRow("Sueldo", amount: MoneyText((try? Amount(cents: 350_000)) ?? Amount.zero, sign: .positive), isNavigable: true) {}
    }
    .background(Palette.background)
    .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Pressed") {
    FlatRowFace(isPressed: true, isEnabled: true) {
        FlatRowLabel(title: "Préstamos", amount: nil, isNavigable: true)
    }
    .background(Palette.background)
}

#Preview("Disabled") {
    FlatRow("Exportar") {}
        .disabled(true)
        .background(Palette.background)
}
