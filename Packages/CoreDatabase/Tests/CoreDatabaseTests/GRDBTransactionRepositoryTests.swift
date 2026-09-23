@testable import CoreDatabase
import CoreDomain
import Foundation
import GRDB
import Testing

struct GRDBTransactionRepositoryTests {
    private struct StoredColumns: Equatable {
        let occurredAt: String
        let createdAt: Int64
        let updatedAt: Int64
        let syncState: String
    }

    private let august: Month
    private let directory: TemporaryDirectory
    private let database: AppDatabase
    private let repository: GRDBTransactionRepository

    init() throws {
        august = try Month(year: 2026, month: 8)
        directory = try TemporaryDirectory()
        database = try AppDatabase.open(at: directory.databaseURL)
        let clock: FixedClock = FixedClock(now: Date(timeIntervalSince1970: 1_790_091_000.25))
        repository = GRDBTransactionRepository(database: database, clock: clock)
    }

    @Test("keeps both ends of August in its window and drops the seconds either side")
    func windowsTheMonth() async throws {
        try await repository.create(makeTransaction("july-last", occurredAt: OccurredAt(year: 2026, month: 7, day: 31, hour: 23, minute: 59, second: 59)))
        try await repository.create(makeTransaction("august-first", occurredAt: OccurredAt(year: 2026, month: 8, day: 1, hour: 0, minute: 0, second: 0)))
        try await repository.create(makeTransaction("august-last", occurredAt: OccurredAt(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 59)))
        try await repository.create(makeTransaction("september-first", occurredAt: OccurredAt(year: 2026, month: 9, day: 1, hour: 0, minute: 0, second: 0)))

        let augustTransactions: [Transaction] = try await firstValue(of: repository.transactions(in: august))

        let ids: Set<String> = Set(augustTransactions.map { (transaction: Transaction) -> String in transaction.id.rawValue })
        #expect(ids == ["august-first", "august-last"])
    }

    @Test("hides a soft-deleted movement from its Month")
    func hidesSoftDeleted() async throws {
        try await repository.create(makeTransaction("kept", occurredAt: OccurredAt(year: 2026, month: 8, day: 10, hour: 9, minute: 0, second: 0)))
        try await repository.create(makeTransaction("deleted", occurredAt: OccurredAt(year: 2026, month: 8, day: 11, hour: 9, minute: 0, second: 0)))
        try await database.writer.write { (db: Database) throws in
            try db.execute(sql: "UPDATE transactions SET deletedAt = 1790091000250 WHERE transactionId = 'deleted'")
        }

        let augustTransactions: [Transaction] = try await firstValue(of: repository.transactions(in: august))

        #expect(augustTransactions.map { (transaction: Transaction) -> String in transaction.id.rawValue } == ["kept"])
    }

    @Test("refuses a Spend filed under an Income category and stores nothing")
    func refusesSpendUnderIncomeCategory() async throws {
        let spendUnderIncome: Transaction = try makeTransaction(
            "mismatched",
            occurredAt: OccurredAt(year: 2026, month: 8, day: 12, hour: 9, minute: 0, second: 0),
            categoryID: CategoryID.seededSalary
        )

        await #expect(throws: DomainError.storageFailure) {
            try await repository.create(spendUnderIncome)
        }
        let augustTransactions: [Transaction] = try await firstValue(of: repository.transactions(in: august))
        #expect(augustTransactions.isEmpty)
    }

    @Test("records a write in a Month sequence subscribed before it")
    func recordsWriteAfterSubscribing() async throws {
        let lunch: Transaction = try makeTransaction(
            "lunch",
            occurredAt: OccurredAt(year: 2026, month: 8, day: 14, hour: 13, minute: 5, second: 30),
            categoryID: CategoryID.seededGroceries
        )
        var iterator: any AsyncIteratorProtocol<[Transaction], DomainError> = repository.transactions(in: august).makeAsyncIterator()
        var recorded: [[Transaction]] = []

        recorded.append(try #require(try await iterator.next(isolation: #isolation)))
        try await repository.create(lunch)
        recorded.append(try #require(try await iterator.next(isolation: #isolation)))

        #expect(recorded == [[], [lunch]])
    }

    @Test("stores occurredAt as zone-less text and stamps createdAt and updatedAt with the clock's epoch ms")
    func storesTextAndEpochMilliseconds() async throws {
        try await repository.create(makeTransaction("stamped", occurredAt: OccurredAt(year: 2026, month: 8, day: 5, hour: 7, minute: 8, second: 9)))

        let stored: StoredColumns? = try await database.writer.read { (db: Database) throws -> StoredColumns? in
            try Row.fetchOne(db, sql: "SELECT occurredAt, createdAt, updatedAt, syncState FROM transactions WHERE transactionId = 'stamped'")
                .map { (row: Row) -> StoredColumns in
                    StoredColumns(occurredAt: row["occurredAt"], createdAt: row["createdAt"], updatedAt: row["updatedAt"], syncState: row["syncState"])
                }
        }

        #expect(stored == StoredColumns(occurredAt: "2026-08-05T07:08:09", createdAt: 1_790_091_000_250, updatedAt: 1_790_091_000_250, syncState: "Pending"))
    }

    @Test("keeps a movement on or after the window start and drops the second before it")
    func windowsFromStart() async throws {
        let start: OccurredAt = try OccurredAt(year: 2026, month: 6, day: 24, hour: 0, minute: 0, second: 0)
        try await repository.create(makeTransaction(
            "counted",
            occurredAt: start,
            categoryID: CategoryID.seededGroceries
        ))
        try await repository.create(makeTransaction(
            "excluded",
            occurredAt: try OccurredAt(year: 2026, month: 6, day: 23, hour: 23, minute: 59, second: 59),
            categoryID: CategoryID.seededGroceries
        ))

        let fromStart: [Transaction] = try await firstValue(of: repository.transactions(from: start))

        #expect(fromStart.map { (transaction: Transaction) -> String in transaction.id.rawValue } == ["counted"])
    }

    @Test("never yields a combo whose Account is soft-deleted")
    func hidesSoftDeletedAccount() async throws {
        try await database.writer.write { (db: Database) throws in
            try db.execute(sql: """
                INSERT INTO accounts (accountId, name, type, currency, createdAt, updatedAt, deletedAt) VALUES
                ('closed', 'Vieja', 'Bank', 'PEN', 1790040000000, 1790040000000, 1790050000000)
                """)
            try db.execute(sql: """
                INSERT INTO transactions (transactionId, type, amount, occurredAt, categoryId, accountId, createdAt, updatedAt) VALUES
                ('from-closed', 'Spend', 1250, '2026-08-12T09:00:00', ?, 'closed', 1790091000250, 1790091000250)
                """, arguments: [CategoryID.seededGroceries.rawValue])
        }

        let fromStart: [Transaction] = try await firstValue(of: repository.transactions(from: try OccurredAt(year: 2026, month: 8, day: 1, hour: 0, minute: 0, second: 0)))

        #expect(fromStart.isEmpty)
    }

    @Test("never yields a combo whose Category is soft-deleted")
    func hidesSoftDeletedCategory() async throws {
        try await database.writer.write { (db: Database) throws in
            try db.execute(sql: "UPDATE categories SET deletedAt = 1790091000250 WHERE categoryId = ?", arguments: [CategoryID.seededGroceries.rawValue])
        }
        try await repository.create(makeTransaction(
            "under-deleted-category",
            occurredAt: try OccurredAt(year: 2026, month: 8, day: 12, hour: 9, minute: 0, second: 0),
            categoryID: CategoryID.seededGroceries
        ))

        let fromStart: [Transaction] = try await firstValue(of: repository.transactions(from: try OccurredAt(year: 2026, month: 8, day: 1, hour: 0, minute: 0, second: 0)))

        #expect(fromStart.isEmpty)
    }

    @Test("never counts a soft-deleted Transaction")
    func excludesSoftDeletedTransaction() async throws {
        try await repository.create(makeTransaction(
            "kept",
            occurredAt: try OccurredAt(year: 2026, month: 8, day: 12, hour: 9, minute: 0, second: 0),
            categoryID: CategoryID.seededGroceries
        ))
        try await repository.create(makeTransaction(
            "deleted",
            occurredAt: try OccurredAt(year: 2026, month: 8, day: 13, hour: 9, minute: 0, second: 0),
            categoryID: CategoryID.seededGroceries
        ))
        try await database.writer.write { (db: Database) throws in
            try db.execute(sql: "UPDATE transactions SET deletedAt = 1790091000250 WHERE transactionId = 'deleted'")
        }

        let fromStart: [Transaction] = try await firstValue(of: repository.transactions(from: try OccurredAt(year: 2026, month: 8, day: 1, hour: 0, minute: 0, second: 0)))

        #expect(fromStart.map { (transaction: Transaction) -> String in transaction.id.rawValue } == ["kept"])
    }

    private func makeTransaction(
        _ id: String,
        occurredAt: OccurredAt,
        categoryID: CategoryID? = nil
    ) throws -> Transaction {
        Transaction(
            id: TransactionID(id),
            TransactionInsert(
                type: .spend,
                amount: try Amount(cents: 1_250),
                description: "Almuerzo",
                occurredAt: occurredAt,
                accountID: AccountID.seededCash,
                categoryID: categoryID
            )
        )
    }

    private func firstValue(of sequence: any AsyncSequence<[Transaction], DomainError>) async throws -> [Transaction] {
        var iterator: any AsyncIteratorProtocol<[Transaction], DomainError> = sequence.makeAsyncIterator()
        return try #require(try await iterator.next(isolation: #isolation))
    }
}
