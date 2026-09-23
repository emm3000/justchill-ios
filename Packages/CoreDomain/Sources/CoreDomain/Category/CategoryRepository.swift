public protocol CategoryRepository: Sendable {
    var categories: any AsyncSequence<[Category], DomainError> { get }
}
