import CoreDomain
import CoreUI
import SwiftUI

struct MonthDaySection: View {
    let title: String
    let transactions: [CoreDomain.Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(verbatim: title)
                .font(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
                .padding(.horizontal, Spacing.s4)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(transactions, id: \.id) { (transaction: CoreDomain.Transaction) in
                    FlatRow(Self.rowTitle(of: transaction), amount: Self.rowMoney(of: transaction))
                }
            }
        }
    }

    private static func rowTitle(of transaction: CoreDomain.Transaction) -> String {
        transaction.description.isEmpty ? "Sin categoría" : transaction.description
    }

    private static func rowMoney(of transaction: CoreDomain.Transaction) -> MoneyText {
        MoneyText(transaction.amount, sign: transaction.type == .income ? .positive : .unsigned)
    }
}
