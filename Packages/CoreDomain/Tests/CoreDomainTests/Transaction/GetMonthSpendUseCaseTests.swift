import CoreDomain
import Testing

struct GetMonthSpendUseCaseTests {
    private let august: Month
    private let cashAccountID: AccountID = AccountID("cash")

    init() throws {
        august = try Month(year: 2026, month: 8)
    }

    @Test("answers zero for a Month with no movements")
    func zeroWhenEmpty() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let getMonthSpend: GetMonthSpendUseCase = GetMonthSpendUseCase(transactions: repository)
        var totals: any AsyncIteratorProtocol<Amount, DomainError> = getMonthSpend(august).makeAsyncIterator()

        let firstTotal: Amount? = try await totals.next(isolation: #isolation)

        #expect(firstTotal == Amount.zero)
    }

    @Test("totals the Month's Spend again after each write, leaving Income out")
    func recordsTotalsAcrossWrites() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let getMonthSpend: GetMonthSpendUseCase = GetMonthSpendUseCase(transactions: repository)
        var totals: any AsyncIteratorProtocol<Amount, DomainError> = getMonthSpend(august).makeAsyncIterator()
        var recorded: [Amount] = []

        recorded.append(try #require(try await totals.next(isolation: #isolation)))
        try await repository.create(makeTransaction("lunch", .spend, cents: 1_250, day: 12))
        recorded.append(try #require(try await totals.next(isolation: #isolation)))
        try await repository.create(makeTransaction("salary", .income, cents: 500_000, day: 15))
        recorded.append(try #require(try await totals.next(isolation: #isolation)))
        try await repository.create(makeTransaction("taxi", .spend, cents: 899, day: 31))
        recorded.append(try #require(try await totals.next(isolation: #isolation)))

        let expected: [Amount] = try [0, 1_250, 1_250, 2_149].map { (cents: Int64) throws -> Amount in try Amount(cents: cents) }
        #expect(recorded == expected)
    }

    private func makeTransaction(_ id: String, _ type: TransactionType, cents: Int64, day: Int) throws -> Transaction {
        Transaction(
            id: TransactionID(id),
            TransactionInsert(
                type: type,
                amount: try Amount(cents: cents),
                description: "",
                occurredAt: try OccurredAt(year: 2026, month: 8, day: day, hour: 12, minute: 0, second: 0),
                accountID: cashAccountID,
                categoryID: nil
            )
        )
    }
}
