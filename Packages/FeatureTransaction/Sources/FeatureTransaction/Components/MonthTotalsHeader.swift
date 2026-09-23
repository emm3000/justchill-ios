import CoreDomain
import CoreUI
import SwiftUI

struct MonthTotalsHeader: View {
    let spend: Amount
    let income: Amount

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(verbatim: "Gastado este mes")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                AmountDisplay(spend)
            }
            .accessibilityElement(children: .combine)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s4) { figures }
                VStack(alignment: .leading, spacing: Spacing.s1) { figures }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var figures: some View {
        MonthFigure(label: "Entró", money: MoneyText(income))
        MonthFigure(label: "Neto", money: MoneyText(netOf: income, minus: spend))
    }
}

private struct MonthFigure: View {
    let label: String
    let money: MoneyText

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize

    var body: some View {
        figure
            .foregroundStyle(Palette.textSecondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(label): \(money.spokenText)"))
    }

    @ViewBuilder
    private var figure: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                labelText
                amountText
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        } else {
            Text("\(labelText) \(amountText)")
        }
    }

    private var labelText: Text {
        Text(verbatim: label)
            .font(Typography.body)
    }

    private var amountText: Text {
        Text(verbatim: money.text)
            .font(Typography.amountRow)
            .foregroundStyle(money.sign.minorTint)
    }
}

#Preview("Neto positive") {
    MonthTotalsHeader(spend: (try? Amount(cents: 184_250)) ?? Amount.zero, income: (try? Amount(cents: 350_000)) ?? Amount.zero)
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Neto zero") {
    MonthTotalsHeader(spend: Amount.zero, income: Amount.zero)
        .padding(Spacing.s4)
        .background(Palette.background)
}

#Preview("Accessibility size") {
    MonthTotalsHeader(spend: (try? Amount(cents: 384_250)) ?? Amount.zero, income: (try? Amount(cents: 350_000)) ?? Amount.zero)
        .padding(Spacing.s4)
        .background(Palette.background)
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Neto negative") {
    MonthTotalsHeader(spend: (try? Amount(cents: 184_250)) ?? Amount.zero, income: (try? Amount(cents: 100_000)) ?? Amount.zero)
        .padding(Spacing.s4)
        .background(Palette.background)
}
