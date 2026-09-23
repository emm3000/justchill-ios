import CoreDomain
import CoreUI
import SwiftUI

struct MonthContent: View {
    let month: Month
    let today: OccurredAt
    let presentation: MonthPresentation?
    let failure: DomainError?
    let onDismissFailure: () -> Void

    var body: some View {
        ScrollView {
            if let presentation: MonthPresentation = presentation {
                loaded(presentation)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .navigationTitle(MonthText(month).text)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Algo salió mal", isPresented: isShowingFailure) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(verbatim: failure?.message ?? "")
        }
    }

    private func loaded(_ presentation: MonthPresentation) -> some View {
        LazyVStack(alignment: .leading, spacing: Spacing.s6) {
            MonthTotalsHeader(spend: presentation.spend, income: presentation.income)
                .padding(.horizontal, Spacing.s4)
            if presentation.days.isEmpty {
                Text(verbatim: "Aún no hay movimientos este mes.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Spacing.s4)
            }
            ForEach(presentation.days) { (day: DayPresentation) in
                MonthDaySection(title: DayText(day.day, of: month, today: today).text, transactions: day.transactions)
            }
        }
        .padding(.vertical, Spacing.s4)
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: { failure != nil },
            set: { (isPresented: Bool) in
                if !isPresented { onDismissFailure() }
            }
        )
    }
}

private enum MonthPreview {
    static let today: OccurredAt = OccurredAt(Date(timeIntervalSince1970: 1_790_071_200), in: .gmt)

    static func transaction(
        _ id: String,
        _ type: TransactionType,
        cents: Int64,
        day: Int,
        hour: Int,
        description: String
    ) -> CoreDomain.Transaction? {
        guard let amount: Amount = try? Amount(cents: cents),
              let occurredAt: OccurredAt = try? OccurredAt(year: 2026, month: 9, day: day, hour: hour, minute: 0, second: 0)
        else { return nil }
        let insert: TransactionInsert = TransactionInsert(
            type: type,
            amount: amount,
            description: description,
            occurredAt: occurredAt,
            accountID: AccountID("cash"),
            categoryID: nil
        )
        return CoreDomain.Transaction(id: TransactionID(id), insert)
    }

    static func content(_ transactions: [CoreDomain.Transaction?], failure: DomainError? = nil) -> some View {
        let stored: [CoreDomain.Transaction] = transactions.compactMap { (transaction: CoreDomain.Transaction?) in transaction }
        return NavigationStack {
            MonthContent(
                month: today.month,
                today: today,
                presentation: MonthPresentation(stored),
                failure: failure,
                onDismissFailure: {}
            )
        }
    }
}

#Preview("Two days") {
    MonthPreview.content([
        MonthPreview.transaction("salary", .income, cents: 350_000, day: 22, hour: 9, description: "Sueldo"),
        MonthPreview.transaction("taxi", .spend, cents: 1_200, day: 22, hour: 8, description: ""),
        MonthPreview.transaction("lunch", .spend, cents: 2_450, day: 21, hour: 13, description: "Almuerzo"),
        MonthPreview.transaction("market", .spend, cents: 18_000, day: 14, hour: 18, description: "Mercado"),
    ])
}

#Preview("Neto negative") {
    MonthPreview.content([
        MonthPreview.transaction("rent", .spend, cents: 120_000, day: 1, hour: 9, description: "Alquiler"),
        MonthPreview.transaction("gig", .income, cents: 50_000, day: 21, hour: 13, description: ""),
    ])
}

#Preview("Empty") {
    MonthPreview.content([])
}

#Preview("Storage failure") {
    MonthPreview.content([], failure: .storageFailure)
}

#Preview("Accessibility size") {
    MonthPreview.content([
        MonthPreview.transaction("salary", .income, cents: 350_000, day: 22, hour: 9, description: "Sueldo"),
        MonthPreview.transaction("lunch", .spend, cents: 2_450, day: 21, hour: 13, description: "Almuerzo"),
    ])
    .environment(\.dynamicTypeSize, .accessibility3)
}
