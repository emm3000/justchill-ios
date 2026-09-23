import CoreDomain

public struct InMemoryAccountRepository: AccountRepository {
    private let live: [Account]

    public init(accounts: [Account]) {
        live = accounts
    }

    public var accounts: any AsyncSequence<[Account], DomainError> {
        let (stream, continuation): (AsyncStream<[Account]>, AsyncStream<[Account]>.Continuation) =
            AsyncStream.makeStream(of: [Account].self)
        continuation.yield(live)
        return NeverFailingSequence(stream)
    }
}
