import CoreDomain
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct MonthFailureTests {
    private let fixture: MonthFixture

    init() throws {
        fixture = try MonthFixture()
    }

    @Test("holds a storage failure until it is dismissed")
    func holdsStorageFailure() async {
        let model: MonthModel = fixture.makeModel(transactions: FailingTransactionRepository(failure: .storageFailure))
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }

        await model.waitForFailure()

        #expect(model.failure == .storageFailure)
        model.dismissFailure()
        #expect(model.failure == nil)
    }
}
