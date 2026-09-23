import CoreDomain
import Foundation
import Synchronization

public final class InMemoryTransactionRepository: TransactionRepository {
    private struct Subscriber {
        let month: Month
        let continuation: AsyncStream<[Transaction]>.Continuation
    }

    private struct State {
        var transactions: [Transaction]
        var subscribers: [UUID: Subscriber] = [:]
    }

    private let state: Mutex<State>
    private let createFailure: DomainError?

    public init(transactions: [Transaction] = [], createFailure: DomainError? = nil) {
        state = Mutex(State(transactions: transactions))
        self.createFailure = createFailure
    }

    public var stored: [Transaction] {
        state.withLock { (state: inout State) -> [Transaction] in state.transactions }
    }

    public func create(_ transaction: Transaction) async throws(DomainError) {
        await Task.yield()
        if let createFailure { throw createFailure }
        state.withLock { (state: inout State) in
            state.transactions.append(transaction)
            for subscriber: Subscriber in state.subscribers.values {
                subscriber.continuation.yield(state.transactions.inMonth(subscriber.month))
            }
        }
    }

    public func transactions(in month: Month) -> any AsyncSequence<[Transaction], DomainError> {
        let (stream, continuation): (AsyncStream<[Transaction]>, AsyncStream<[Transaction]>.Continuation) =
            AsyncStream.makeStream(of: [Transaction].self)
        let subscriberID: UUID = UUID()
        state.withLock { (state: inout State) in
            state.subscribers[subscriberID] = Subscriber(month: month, continuation: continuation)
            continuation.yield(state.transactions.inMonth(month))
        }
        continuation.onTermination = { [weak self] (_: AsyncStream<[Transaction]>.Continuation.Termination) in
            self?.state.withLock { (state: inout State) in state.subscribers[subscriberID] = nil }
        }
        return NeverFailingSequence(stream)
    }
}

private extension [Transaction] {
    func inMonth(_ month: Month) -> [Transaction] {
        filter { (transaction: Transaction) -> Bool in transaction.occurredAt.month == month }
    }
}
