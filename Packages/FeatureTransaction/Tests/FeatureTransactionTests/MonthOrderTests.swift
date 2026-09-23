import CoreDomain
import CoreTesting
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct MonthOrderTests {
    private let fixture: MonthFixture

    init() throws {
        fixture = try MonthFixture()
    }

    @Test("groups the Month by day, newest day first, rows newest first and ties by TransactionID")
    func groupsAndOrders() async throws {
        let transactions: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: [
            try fixture.makeTransaction("lunch", .spend, cents: 1_250, day: 21, hour: 13),
            try fixture.makeTransaction("taxi-b", .spend, cents: 900, day: 22, hour: 8),
            try fixture.makeTransaction("salary", .income, cents: 350_000, day: 22, hour: 9),
            try fixture.makeTransaction("taxi-a", .spend, cents: 800, day: 22, hour: 8),
            try fixture.makeTransaction("dinner", .spend, cents: 3_000, day: 21, hour: 20),
        ])
        let model: MonthModel = fixture.makeModel(transactions: transactions)
        let observing: Task<Void, Never> = Task { await model.observe() }
        defer { observing.cancel() }

        let presentation: MonthPresentation = try #require(await model.waitUntilLoaded())

        #expect(presentation.days.map(\.day) == [22, 21])
        #expect(presentation.days.map { (day: DayPresentation) -> [String] in day.transactions.map(\.id.rawValue) } == [
            ["salary", "taxi-a", "taxi-b"],
            ["dinner", "lunch"],
        ])
    }

    @Test("derives the Month and today from the injected Clock in the injected TimeZone, not in UTC")
    func derivesMonthFromClock() throws {
        let lastNightOfSeptemberInLima: FixedClock = try FixedClock("2026-10-01T03:00:00Z")
        let model: MonthModel = MonthModel(
            transactions: InMemoryTransactionRepository(),
            clock: lastNightOfSeptemberInLima,
            zone: fixture.lima
        )

        #expect(model.month == (try Month(year: 2026, month: 9)))
        #expect(model.today.day == 30)
    }
}
