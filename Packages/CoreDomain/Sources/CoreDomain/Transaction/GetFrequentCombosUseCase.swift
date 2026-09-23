import Foundation

public struct GetFrequentCombosUseCase: Sendable {
    private static let windowDays: Int = 90

    private let transactions: any TransactionRepository
    private let clock: any Clock
    private let zone: TimeZone

    public init(transactions: any TransactionRepository, clock: any Clock, zone: TimeZone) {
        self.transactions = transactions
        self.clock = clock
        self.zone = zone
    }

    public func callAsFunction() -> any AsyncSequence<[FrequentCombo], DomainError> {
        rankedCombos(of: transactions.transactions(from: windowStart))
    }

    private func rankedCombos<WindowTransactions: AsyncSequence<[Transaction], DomainError>>(
        of windowTransactions: WindowTransactions
    ) -> any AsyncSequence<[FrequentCombo], DomainError> {
        windowTransactions.map { (transactions: [Transaction]) -> [FrequentCombo] in transactions.rankedFrequentCombos() }
    }

    private var windowStart: OccurredAt {
        let calendar: Calendar = Calendar.wallClock(in: zone)
        let startOfToday: Date = calendar.startOfDay(for: clock.now)
        let windowStartInstant: Date = calendar.date(byAdding: .day, value: -Self.windowDays, to: startOfToday) ?? startOfToday
        return OccurredAt(windowStartInstant, in: zone)
    }
}

private struct FrequentComboAggregate {
    var count: Int
    var latestOccurredAt: OccurredAt
}

private extension [Transaction] {
    func rankedFrequentCombos() -> [FrequentCombo] {
        var aggregates: [FrequentCombo: FrequentComboAggregate] = [:]
        for transaction: Transaction in self {
            guard let categoryID: CategoryID = transaction.categoryID else { continue }
            let combo: FrequentCombo = FrequentCombo(accountID: transaction.accountID, categoryID: categoryID, type: transaction.type)
            if var aggregate: FrequentComboAggregate = aggregates[combo] {
                aggregate.count += 1
                aggregate.latestOccurredAt = Swift.max(aggregate.latestOccurredAt, transaction.occurredAt)
                aggregates[combo] = aggregate
            } else {
                aggregates[combo] = FrequentComboAggregate(count: 1, latestOccurredAt: transaction.occurredAt)
            }
        }

        return aggregates
            .sorted { (lhs: (key: FrequentCombo, value: FrequentComboAggregate), rhs: (key: FrequentCombo, value: FrequentComboAggregate)) -> Bool in
                if lhs.value.count != rhs.value.count { return lhs.value.count > rhs.value.count }
                if lhs.value.latestOccurredAt != rhs.value.latestOccurredAt {
                    return lhs.value.latestOccurredAt > rhs.value.latestOccurredAt
                }
                if lhs.key.accountID.rawValue != rhs.key.accountID.rawValue {
                    return lhs.key.accountID.rawValue < rhs.key.accountID.rawValue
                }
                if lhs.key.categoryID.rawValue != rhs.key.categoryID.rawValue {
                    return lhs.key.categoryID.rawValue < rhs.key.categoryID.rawValue
                }
                return lhs.key.type.rawValue < rhs.key.type.rawValue
            }
            .map { (entry: (key: FrequentCombo, value: FrequentComboAggregate)) -> FrequentCombo in entry.key }
    }
}
