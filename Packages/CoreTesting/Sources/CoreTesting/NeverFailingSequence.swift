import CoreDomain

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
