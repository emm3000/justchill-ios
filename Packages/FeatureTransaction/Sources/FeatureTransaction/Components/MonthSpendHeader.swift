import CoreDomain
import CoreUI
import SwiftUI

struct MonthSpendHeader: View {
    let spend: Amount?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(verbatim: "Gastado este mes")
                .font(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
            Text(verbatim: money.text)
                .font(Typography.amountRow)
                .foregroundStyle(Palette.textSecondary)
                .contentTransition(.numericText())
                .opacity(spend == nil ? 0 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Gastado este mes: \(money.spokenText)"))
        .animation(Motion.signature, value: spend)
    }

    private var money: MoneyText {
        MoneyText(spend ?? Amount.zero)
    }
}

#Preview("Loaded") {
    MonthSpendHeader(spend: (try? Amount(cents: 184_250)) ?? Amount.zero)
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Loading") {
    MonthSpendHeader(spend: nil)
        .padding(Spacing.s4)
        .background(Palette.background)
}
