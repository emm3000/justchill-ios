import Foundation

public struct CreateTransactionUseCase: Sendable {
    private let transactions: any TransactionRepository
    private let clock: any Clock
    private let zone: TimeZone

    public init(transactions: any TransactionRepository, clock: any Clock, zone: TimeZone) {
        self.transactions = transactions
        self.clock = clock
        self.zone = zone
    }

    public func callAsFunction(_ insert: TransactionInsert) async throws(DomainError) -> TransactionID {
        guard insert.amount != Amount.zero else { throw DomainError.zeroAmount }
        let today: OccurredAt = OccurredAt(clock.now, in: zone)
        guard !insert.occurredAt.isOnLaterDay(than: today) else { throw DomainError.occurredAfterToday }
        let transaction: Transaction = Transaction(id: TransactionID(UUID().uuidString), insert)
        try await transactions.create(transaction)
        return transaction.id
    }
}
