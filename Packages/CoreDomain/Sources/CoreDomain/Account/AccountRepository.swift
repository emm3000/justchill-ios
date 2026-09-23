public protocol AccountRepository: Sendable {
    var accounts: any AsyncSequence<[Account], DomainError> { get }
}
