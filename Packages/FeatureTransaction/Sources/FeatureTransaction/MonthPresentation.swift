import CoreDomain

public struct MonthPresentation: Equatable, Sendable {
    public let spend: Amount
    public let income: Amount
    public let days: [DayPresentation]

    public init(_ transactions: [Transaction]) {
        spend = transactions.total(of: .spend)
        income = transactions.total(of: .income)
        days = transactions.newestFirst.groupedByDay
    }
}

public struct DayPresentation: Equatable, Sendable, Identifiable {
    public let day: Int
    public let transactions: [Transaction]

    public var id: Int {
        day
    }
}

private extension [Transaction] {
    func total(of type: TransactionType) -> Amount {
        filter { (transaction: Transaction) -> Bool in transaction.type == type }
            .reduce(Amount.zero) { (total: Amount, transaction: Transaction) -> Amount in total + transaction.amount }
    }

    var newestFirst: [Transaction] {
        sorted { (lhs: Transaction, rhs: Transaction) -> Bool in
            guard lhs.occurredAt == rhs.occurredAt else { return lhs.occurredAt > rhs.occurredAt }
            return lhs.id.rawValue < rhs.id.rawValue
        }
    }

    var groupedByDay: [DayPresentation] {
        reduce(into: [DayPresentation]()) { (days: inout [DayPresentation], transaction: Transaction) in
            guard let last: DayPresentation = days.last, last.day == transaction.occurredAt.day else {
                days.append(DayPresentation(day: transaction.occurredAt.day, transactions: [transaction]))
                return
            }
            days[days.count - 1] = DayPresentation(day: last.day, transactions: last.transactions + [transaction])
        }
    }
}
