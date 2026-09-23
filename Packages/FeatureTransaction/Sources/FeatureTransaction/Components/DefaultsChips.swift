import CoreDomain
import CoreUI
import SwiftUI

struct DefaultsChips: View {
    let type: TransactionType
    let accountName: String?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.s2) {
                Chip(typeTitle) {}
                Chip(accountName ?? "Sin cuenta") {}
                Chip("Sin categoría") {}
                Chip("Hoy") {}
            }
            .disabled(true)
        }
        .contentMargins(.horizontal, Spacing.s4, for: .scrollContent)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    private var typeTitle: String {
        switch type {
        case .spend: "Gasto"
        case .income: "Ingreso"
        }
    }
}

#Preview("Spend") {
    DefaultsChips(type: .spend, accountName: "Efectivo")
        .padding(.vertical, Spacing.s4)
        .background(Palette.background)
}

#Preview("Income, no Account") {
    DefaultsChips(type: .income, accountName: nil)
        .padding(.vertical, Spacing.s4)
        .background(Palette.background)
}
