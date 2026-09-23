@testable import CoreDatabase
import CoreDomain
import Testing

struct DomainFailingSequenceTests {
    private typealias Values = DomainFailingSequence<AsyncThrowingStream<Int, any Error>>

    private struct DriverFailure: Error {}

    @Test("ends the sequence when the observation is cancelled instead of failing it")
    func endsOnCancellation() async throws {
        let values: Values = Values(stream(yielding: 1, finishingWith: CancellationError()))
        var iterator: Values.AsyncIterator = values.makeAsyncIterator()

        let first: Int? = try await iterator.next(isolation: #isolation)
        let afterCancellation: Int? = try await iterator.next(isolation: #isolation)

        #expect(first == 1)
        #expect(afterCancellation == nil)
    }

    @Test("fails with storageFailure when the database fails")
    func translatesDatabaseFailure() async throws {
        let values: Values = Values(stream(yielding: 1, finishingWith: DriverFailure()))
        var iterator: Values.AsyncIterator = values.makeAsyncIterator()

        _ = try await iterator.next(isolation: #isolation)

        await #expect(throws: DomainError.storageFailure) {
            _ = try await iterator.next(isolation: #isolation)
        }
    }

    @Test("passes a DomainError raised while reading rows through unchanged")
    func keepsDomainError() async throws {
        let values: Values = Values(stream(yielding: 1, finishingWith: DomainError.impossibleOccurredAt))
        var iterator: Values.AsyncIterator = values.makeAsyncIterator()

        _ = try await iterator.next(isolation: #isolation)

        await #expect(throws: DomainError.impossibleOccurredAt) {
            _ = try await iterator.next(isolation: #isolation)
        }
    }

    private func stream(yielding value: Int, finishingWith failure: any Error) -> AsyncThrowingStream<Int, any Error> {
        AsyncThrowingStream { (continuation: AsyncThrowingStream<Int, any Error>.Continuation) in
            continuation.yield(value)
            continuation.finish(throwing: failure)
        }
    }
}
