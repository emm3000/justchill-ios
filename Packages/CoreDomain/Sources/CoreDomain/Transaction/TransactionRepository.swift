public protocol TransactionRepository: Sendable {
    func create(_ transaction: Transaction) async throws(DomainError)
    func transactions(in month: Month) -> any AsyncSequence<[Transaction], DomainError>
    func categorizedTransactions(from start: OccurredAt) -> any AsyncSequence<[Transaction], DomainError>
}
