import CoreDomain

nonisolated struct FailingTransactionRepository: TransactionRepository {
    let failure: DomainError

    func create(_ transaction: Transaction) async throws(DomainError) {
        throw failure
    }

    func transactions(in month: Month) -> any AsyncSequence<[Transaction], DomainError> {
        FailingTransactions(failure: failure)
    }

    func categorizedTransactions(from start: OccurredAt) -> any AsyncSequence<[Transaction], DomainError> {
        FailingTransactions(failure: failure)
    }
}

nonisolated private struct FailingTransactions: AsyncSequence {
    typealias Failure = DomainError

    struct AsyncIterator: AsyncIteratorProtocol {
        let failure: DomainError

        mutating func next(isolation actor: isolated (any Actor)?) async throws(DomainError) -> [Transaction]? {
            throw failure
        }
    }

    let failure: DomainError

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(failure: failure)
    }
}
