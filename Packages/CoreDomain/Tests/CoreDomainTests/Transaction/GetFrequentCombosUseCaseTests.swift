import CoreDomain
import Foundation
import Testing

struct GetFrequentCombosUseCaseTests {
    private let cashAccountID: AccountID = AccountID("cash")
    private let bankAccountID: AccountID = AccountID("bank")
    private let groceriesCategoryID: CategoryID = CategoryID("groceries")
    private let taxiCategoryID: CategoryID = CategoryID("taxi")

    @Test("yields an empty list when there is no history")
    func emptyWhenNoHistory() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let getFrequentCombos: GetFrequentCombosUseCase = try makeUseCase(repository)

        let first: [FrequentCombo] = try await firstValue(of: getFrequentCombos())

        #expect(first.isEmpty)
    }

    @Test("counts a live movement carrying a Category from the start of the day 90 days before today, and excludes the second before it")
    func windowsNinetyDaysByDay() async throws {
        let counted: Transaction = try makeTransaction(
            "counted",
            occurredAt: OccurredAt(year: 2026, month: 6, day: 24, hour: 0, minute: 0, second: 0),
            accountID: cashAccountID,
            categoryID: groceriesCategoryID
        )
        let excluded: Transaction = try makeTransaction(
            "excluded",
            occurredAt: OccurredAt(year: 2026, month: 6, day: 23, hour: 23, minute: 59, second: 59),
            accountID: cashAccountID,
            categoryID: groceriesCategoryID
        )
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: [counted, excluded])
        let getFrequentCombos: GetFrequentCombosUseCase = try makeUseCase(repository)

        let combos: [FrequentCombo] = try await firstValue(of: getFrequentCombos())

        #expect(combos == [FrequentCombo(accountID: cashAccountID, categoryID: groceriesCategoryID, type: .spend)])
    }

    @Test("never forms a combo from an Uncategorized movement")
    func skipsUncategorized() async throws {
        let uncategorized: Transaction = try makeTransaction(
            "uncategorized",
            occurredAt: OccurredAt(year: 2026, month: 9, day: 1, hour: 12, minute: 0, second: 0),
            accountID: cashAccountID,
            categoryID: nil
        )
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: [uncategorized])
        let getFrequentCombos: GetFrequentCombosUseCase = try makeUseCase(repository)

        let combos: [FrequentCombo] = try await firstValue(of: getFrequentCombos())

        #expect(combos.isEmpty)
    }

    @Test("ranks by count, then latest occurredAt, then AccountID, CategoryID and type raw value")
    func ranksByCountThenRecencyThenIdentity() async throws {
        let groceriesCash: [Transaction] = try [
            makeTransaction("g1", occurredAt: OccurredAt(year: 2026, month: 9, day: 1, hour: 9, minute: 0, second: 0), accountID: cashAccountID, categoryID: groceriesCategoryID),
            makeTransaction("g2", occurredAt: OccurredAt(year: 2026, month: 9, day: 5, hour: 9, minute: 0, second: 0), accountID: cashAccountID, categoryID: groceriesCategoryID),
        ]
        let taxiCash: Transaction = try makeTransaction(
            "t1",
            occurredAt: OccurredAt(year: 2026, month: 9, day: 10, hour: 9, minute: 0, second: 0),
            accountID: cashAccountID,
            categoryID: taxiCategoryID
        )
        let groceriesBank: Transaction = try makeTransaction(
            "g3",
            occurredAt: OccurredAt(year: 2026, month: 9, day: 10, hour: 9, minute: 0, second: 0),
            accountID: bankAccountID,
            categoryID: groceriesCategoryID
        )
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository(transactions: groceriesCash + [taxiCash, groceriesBank])
        let getFrequentCombos: GetFrequentCombosUseCase = try makeUseCase(repository)

        let combos: [FrequentCombo] = try await firstValue(of: getFrequentCombos())

        #expect(combos == [
            FrequentCombo(accountID: cashAccountID, categoryID: groceriesCategoryID, type: .spend),
            FrequentCombo(accountID: bankAccountID, categoryID: groceriesCategoryID, type: .spend),
            FrequentCombo(accountID: cashAccountID, categoryID: taxiCategoryID, type: .spend),
        ])
    }

    @Test("yields again after a Transaction is created")
    func yieldsAgainAfterCreate() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let getFrequentCombos: GetFrequentCombosUseCase = try makeUseCase(repository)
        var iterator: any AsyncIteratorProtocol<[FrequentCombo], DomainError> = getFrequentCombos().makeAsyncIterator()
        var recorded: [[FrequentCombo]] = []

        recorded.append(try #require(try await iterator.next(isolation: #isolation)))
        try await repository.create(makeTransaction(
            "lunch",
            occurredAt: OccurredAt(year: 2026, month: 9, day: 20, hour: 12, minute: 0, second: 0),
            accountID: cashAccountID,
            categoryID: groceriesCategoryID
        ))
        recorded.append(try #require(try await iterator.next(isolation: #isolation)))

        #expect(recorded == [[], [FrequentCombo(accountID: cashAccountID, categoryID: groceriesCategoryID, type: .spend)]])
    }

    private func makeUseCase(_ repository: InMemoryTransactionRepository) throws -> GetFrequentCombosUseCase {
        GetFrequentCombosUseCase(
            transactions: repository,
            clock: try FixedClock("2026-09-22T12:00:00Z"),
            zone: try TimeZone.fixture("America/Lima")
        )
    }

    private func makeTransaction(
        _ id: String,
        occurredAt: OccurredAt,
        accountID: AccountID,
        categoryID: CategoryID?
    ) throws -> Transaction {
        Transaction(
            id: TransactionID(id),
            TransactionInsert(
                type: .spend,
                amount: try Amount(cents: 1_000),
                description: "",
                occurredAt: occurredAt,
                accountID: accountID,
                categoryID: categoryID
            )
        )
    }

    private func firstValue(of sequence: any AsyncSequence<[FrequentCombo], DomainError>) async throws -> [FrequentCombo] {
        var iterator: any AsyncIteratorProtocol<[FrequentCombo], DomainError> = sequence.makeAsyncIterator()
        return try #require(try await iterator.next(isolation: #isolation))
    }
}
