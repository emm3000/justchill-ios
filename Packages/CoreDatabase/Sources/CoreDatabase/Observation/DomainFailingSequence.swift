import CoreDomain

struct DomainFailingSequence<Base: AsyncSequence>: AsyncSequence {
    typealias Element = Base.Element
    typealias Failure = DomainError

    struct AsyncIterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator

        mutating func next(isolation actor: isolated (any Actor)?) async throws(DomainError) -> Element? {
            do {
                return try await base.next(isolation: actor)
            } catch is CancellationError {
                return nil
            } catch {
                throw DomainError(translating: error)
            }
        }
    }

    private let base: Base

    init(_ base: Base) {
        self.base = base
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: base.makeAsyncIterator())
    }
}
