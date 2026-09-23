import CoreDomain

public struct InMemoryCategoryRepository: CategoryRepository {
    private let live: [Category]

    public init(categories: [Category]) {
        live = categories
    }

    public var categories: any AsyncSequence<[Category], DomainError> {
        let (stream, continuation): (AsyncStream<[Category]>, AsyncStream<[Category]>.Continuation) =
            AsyncStream.makeStream(of: [Category].self)
        continuation.yield(live)
        return NeverFailingSequence(stream)
    }
}
