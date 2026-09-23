import CoreDomain
import CoreTesting
import CoreUI
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct MonthTotalsTests {
    private let fixture: MonthFixture

    init() throws {
        fixture = try MonthFixture()
    }

    @Test("reduces Gastado, Entró and Neto for a positive, a zero and a negative Month", arguments: [
        (Int64(350_000), Int64(184_250), "+S/ 1,657.50"),
        (Int64(184_250), Int64(184_250), "S/ 0.00"),
        (Int64(100_000), Int64(184_250), "\u{2212}S/ 842.50"),
    ])
    func reducesTotals(incomeCents: Int64, spendCents: Int64, expectedNet: String) async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: [
            try fixture.makeTransaction("salary", .income, cents: incomeCents, day: 1),
            try fixture.makeTransaction("rent", .spend, cents: spendCents - 1_000, day: 2),
            try fixture.makeTransaction("lunch", .spend, cents: 1_000, day: 22),
        ])
        let model: MonthModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }

        let presentation: MonthPresentation = try #require(await model.waitUntilLoaded())

        #expect(presentation.spend == (try Amount(cents: spendCents)))
        #expect(presentation.income == (try Amount(cents: incomeCents)))
        #expect(MoneyText(netOf: presentation.income, minus: presentation.spend).text == expectedNet)
    }

    @Test("moves Gastado from the prior total to the prior total plus a Spend written while observing")
    func followsWrite() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: [
            try fixture.makeTransaction("market", .spend, cents: 4_000, day: 3),
        ])
        let model: MonthModel = fixture.makeModel(transactions: transactions)
        async let recorded: [Amount] = model.recordSpend(count: 2)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }
        _ = await model.waitUntilLoaded()

        try await transactions.create(try fixture.makeTransaction("lunch", .spend, cents: 1_250, day: 22))

        #expect(await recorded == [try Amount(cents: 4_000), try Amount(cents: 5_250)])
    }
}
