import CoreDomain
import SwiftUI

public struct AmountDisplay: View {
    private let money: MoneyText

    public init(_ amount: Amount, sign: MoneySign = .unsigned) {
        money = MoneyText(amount, sign: sign)
    }

    public var body: some View {
        Text("\(minor(money.prefix))\(major(money.integer))\(minor(money.fraction))")
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .accessibilityLabel(Text(verbatim: money.spokenText))
    }

    private func major(_ part: String) -> Text {
        Text(verbatim: part)
            .font(Typography.amountHero)
            .foregroundStyle(money.sign.tint)
    }

    private func minor(_ part: String) -> Text {
        Text(verbatim: part)
            .font(Typography.amountHeroMinor)
            .foregroundStyle(money.sign.minorTint)
    }
}

#Preview("Unsigned") {
    AmountDisplay((try? Amount(cents: 123_456)) ?? Amount.zero)
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
}

#Preview("Income") {
    AmountDisplay((try? Amount(cents: 123_456)) ?? Amount.zero, sign: .positive)
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
}

#Preview("Zero") {
    AmountDisplay(Amount.zero)
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
}

#Preview("Accessibility size") {
    AmountDisplay((try? Amount(cents: 123_456_789)) ?? Amount.zero)
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .environment(\.dynamicTypeSize, .accessibility3)
}
