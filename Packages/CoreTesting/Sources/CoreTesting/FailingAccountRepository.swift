import CoreDomain

public struct FailingAccountRepository: AccountRepository {
    private let failure: DomainError

    public init(failure: DomainError) {
        self.failure = failure
    }

    public var accounts: any AsyncSequence<[Account], DomainError> {
        FailingSequence<[Account]>(failure: failure)
    }
}

struct FailingSequence<Element: Sendable>: AsyncSequence {
    typealias Failure = DomainError

    struct AsyncIterator: AsyncIteratorProtocol {
        let failure: DomainError

        mutating func next(isolation actor: isolated (any Actor)?) async throws(DomainError) -> Element? {
            throw failure
        }
    }

    let failure: DomainError

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(failure: failure)
    }
}
