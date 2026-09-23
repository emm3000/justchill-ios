import CoreDomain
import CoreTesting
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct AmountPadFailureTests {
    private let fixture: AmountPadFixture

    init() throws {
        fixture = try AmountPadFixture()
    }

    @Test("holds a storage failure and keeps the typed Amount until the failure is dismissed")
    func holdsStorageFailure() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository(createFailure: .storageFailure)
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.enter(digit: 7)
        await model.save()

        #expect(model.failure == .storageFailure)
        #expect(model.amount == (try Amount(cents: 700)))
        model.dismissFailure()
        #expect(model.failure == nil)
    }

    @Test("holds a storage failure when the Accounts cannot be read")
    func holdsReadFailure() async {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(
            transactions: transactions,
            accounts: FailingAccountRepository(failure: .storageFailure)
        )
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }

        await model.waitForFailure()

        #expect(model.failure == .storageFailure)
    }

    @Test("holds no failure when the save is cancelled")
    func cancelledSaveIsNoFailure() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository(createFailure: .storageFailure)
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()
        model.enter(digit: 7)

        let saving: Task<Void, Never> = Task { await model.save() }
        saving.cancel()
        await saving.value

        #expect(model.failure == nil)
        #expect(model.amount == (try Amount(cents: 700)))
    }
}
