import CoreDomain
import Foundation
import Synchronization

final class InMemoryTransactionRepository: TransactionRepository {
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

    init(transactions: [Transaction] = []) {
        state = Mutex(State(transactions: transactions))
    }

    var stored: [Transaction] {
        state.withLock { (state: inout State) -> [Transaction] in state.transactions }
    }

    func create(_ transaction: Transaction) async throws(DomainError) {
        state.withLock { (state: inout State) in
            state.transactions.append(transaction)
            for subscriber: MonthSubscriber in state.monthSubscribers.values {
                subscriber.continuation.yield(state.transactions.inMonth(subscriber.month))
            }
            for subscriber: SinceSubscriber in state.sinceSubscribers.values {
                subscriber.continuation.yield(state.transactions.since(subscriber.start))
            }
        }
    }

    func transactions(in month: Month) -> any AsyncSequence<[Transaction], DomainError> {
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

    func transactions(from start: OccurredAt) -> any AsyncSequence<[Transaction], DomainError> {
        let (stream, continuation): (AsyncStream<[Transaction]>, AsyncStream<[Transaction]>.Continuation) =
            AsyncStream.makeStream(of: [Transaction].self)
        let subscriberID: UUID = UUID()
        state.withLock { (state: inout State) in
            state.sinceSubscribers[subscriberID] = SinceSubscriber(start: start, continuation: continuation)
            continuation.yield(state.transactions.since(start))
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

    func since(_ start: OccurredAt) -> [Transaction] {
        filter { (transaction: Transaction) -> Bool in transaction.occurredAt >= start }
    }
}

struct NeverFailingSequence<Element: Sendable>: AsyncSequence {
    typealias Failure = DomainError

    struct AsyncIterator: AsyncIteratorProtocol {
        var base: AsyncStream<Element>.Iterator

        mutating func next(isolation actor: isolated (any Actor)?) async throws(DomainError) -> Element? {
            await base.next(isolation: actor)
        }
    }

    private let base: AsyncStream<Element>

    init(_ base: AsyncStream<Element>) {
        self.base = base
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
}
