import CoreDomain
import Foundation
import Synchronization

public final class InMemoryTransactionRepository: TransactionRepository {
    private struct MonthSubscriber {
        let month: Month
        let continuation: AsyncStream<[Transaction]>.Continuation
    }

    private struct SinceSubscriber {
        let start: OccurredAt
        let continuation: AsyncStream<[Transaction]>.Continuation
    }

    private struct State {
        var transactions: [Transaction]
        var monthSubscribers: [UUID: MonthSubscriber] = [:]
        var sinceSubscribers: [UUID: SinceSubscriber] = [:]
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
        if let createFailure: DomainError = createFailure { throw createFailure }
        state.withLock { (state: inout State) in
            state.transactions.append(transaction)
            for subscriber: MonthSubscriber in state.monthSubscribers.values {
                subscriber.continuation.yield(state.transactions.inMonth(subscriber.month))
            }
            for subscriber: SinceSubscriber in state.sinceSubscribers.values {
                subscriber.continuation.yield(state.transactions.categorized(since: subscriber.start))
            }
        }
    }

    public func transactions(in month: Month) -> any AsyncSequence<[Transaction], DomainError> {
        let (stream, continuation): (AsyncStream<[Transaction]>, AsyncStream<[Transaction]>.Continuation) =
            AsyncStream.makeStream(of: [Transaction].self)
        let subscriberID: UUID = UUID()
        state.withLock { (state: inout State) in
            state.monthSubscribers[subscriberID] = MonthSubscriber(month: month, continuation: continuation)
            continuation.yield(state.transactions.inMonth(month))
        }
        continuation.onTermination = { [weak self] (_: AsyncStream<[Transaction]>.Continuation.Termination) in
            self?.state.withLock { (state: inout State) in state.monthSubscribers[subscriberID] = nil }
        }
        return NeverFailingSequence(stream)
    }

    public func categorizedTransactions(from start: OccurredAt) -> any AsyncSequence<[Transaction], DomainError> {
        let (stream, continuation): (AsyncStream<[Transaction]>, AsyncStream<[Transaction]>.Continuation) =
            AsyncStream.makeStream(of: [Transaction].self)
        let subscriberID: UUID = UUID()
        state.withLock { (state: inout State) in
            state.sinceSubscribers[subscriberID] = SinceSubscriber(start: start, continuation: continuation)
            continuation.yield(state.transactions.categorized(since: start))
        }
        continuation.onTermination = { [weak self] (_: AsyncStream<[Transaction]>.Continuation.Termination) in
            self?.state.withLock { (state: inout State) in state.sinceSubscribers[subscriberID] = nil }
        }
        return NeverFailingSequence(stream)
    }
}

private extension [Transaction] {
    func inMonth(_ month: Month) -> [Transaction] {
        filter { (transaction: Transaction) -> Bool in transaction.occurredAt.month == month }
    }

    func categorized(since start: OccurredAt) -> [Transaction] {
        filter { (transaction: Transaction) -> Bool in transaction.occurredAt >= start && transaction.categoryID != nil }
    }
}
