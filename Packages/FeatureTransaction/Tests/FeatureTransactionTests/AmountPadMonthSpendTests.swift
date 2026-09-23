import CoreDomain
import CoreTesting
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct AmountPadMonthSpendTests {
    private let fixture: AmountPadFixture

    init() throws {
        fixture = try AmountPadFixture()
    }

    @Test("moves the Month's Spend from the prior total to the prior total plus the saved Spend")
    func monthSpendFollowsSave() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: [try fixture.makeMarketSpend()])
        let model: AmountPadModel = fixture.makeModel(transactions: transactions)
        async let recorded: [Amount] = model.recordMonthSpend(count: 2)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        await model.waitUntilLoaded()

        model.enter(digit: 1)
        model.enter(digit: 2)
        model.enterDecimalSeparator()
        model.enter(digit: 5)
        await model.save()

        #expect(await recorded == [try Amount(cents: 4_000), try Amount(cents: 5_250)])
    }
}
