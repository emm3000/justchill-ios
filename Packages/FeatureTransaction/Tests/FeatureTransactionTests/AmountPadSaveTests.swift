import CoreDomain
import CoreTesting
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct AmountPadSaveTests {
    private let fixture: AmountPadFixture

    init() throws {
        fixture = try AmountPadFixture()
    }

    @Test("saves the typed Amount as a Spend on the oldest Account, no Category, now, with no other action")
    func savesWithDefaults() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.enter(digit: 1)
        model.enter(digit: 2)
        model.enterDecimalSeparator()
        model.enter(digit: 5)
        await model.save()

        let saved: Transaction = try #require(transactions.stored.first)
        #expect(transactions.stored.count == 1)
        #expect(saved.type == .spend)
        #expect(saved.amount == (try Amount(cents: 1_250)))
        #expect(saved.accountID == fixture.cashAccount.id)
        #expect(saved.categoryID == nil)
        #expect(saved.description == "")
        #expect(saved.occurredAt == (try OccurredAt(year: 2026, month: 8, day: 31, hour: 23, minute: 30, second: 0)))
    }

    @Test("saves an Income when ± is pressed first")
    func savesIncomeAfterToggle() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.toggleType()
        model.enter(digit: 8)
        await model.save()

        let saved: Transaction = try #require(transactions.stored.first)
        #expect(saved.type == .income)
        #expect(saved.amount == (try Amount(cents: 800)))
    }

    @Test("offers no save at zero and records nothing when asked")
    func noSaveAtZero() async {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.enter(digit: 0)
        model.enterDecimalSeparator()
        await model.save()

        #expect(model.canSave == false)
        #expect(transactions.stored.isEmpty)
    }

    @Test("offers no save with no live Account and records nothing when asked")
    func noSaveWithoutAccount() async {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(transactions: transactions, accounts: InMemoryAccountRepository(accounts: []))
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.enter(digit: 5)
        await model.save()

        #expect(model.canSave == false)
        #expect(transactions.stored.isEmpty)
    }

    @Test("offers save once an Amount is typed and an Account is live")
    func offersSave() async {
        let model: AmountPadModel = fixture.makeModel(transactions: InMemoryTransactionRepository())
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.enter(digit: 5)

        #expect(model.canSave)
    }

    @Test("returns to zero and Spend after a save, holding the saved id")
    func resetsAfterSave() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.toggleType()
        model.enter(digit: 3)
        await model.save()

        let saved: Transaction = try #require(transactions.stored.first)
        #expect(model.amount == Amount.zero)
        #expect(model.type == .spend)
        #expect(model.savedTransactionID == saved.id)
    }

    @Test("records one movement when save is asked twice before the first write finishes")
    func savesOnceWhileSaving() async {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()
        model.enter(digit: 7)

        async let firstSave: Void = model.save()
        async let secondSave: Void = model.save()
        _ = await (firstSave, secondSave)

        #expect(transactions.stored.count == 1)
    }
}
