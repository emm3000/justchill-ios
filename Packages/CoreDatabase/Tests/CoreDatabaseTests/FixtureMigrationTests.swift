@testable import CoreDatabase
import CoreDomain
import Foundation
import GRDB
import Testing

struct FixtureMigrationTests {
    private struct TableCounts: Equatable {
        let accounts: Int
        let categories: Int
        let defaultCategories: Int
        let transactions: Int
        let recurringMovements: Int
        let loans: Int
        let loanPayments: Int
    }

    private let directory: TemporaryDirectory
    private let database: AppDatabase

    init() throws {
        let fixture: URL = try #require(Bundle.module.url(forResource: "v1", withExtension: "sqlite", subdirectory: "Fixtures"))
        directory = try TemporaryDirectory()
        try FileManager.default.copyItem(at: fixture, to: directory.databaseURL)
        database = try AppDatabase.open(at: directory.databaseURL)
    }

    @Test("opens the v1 fixture at head with every table's rows and the seeds intact")
    func keepsRowsAndSeeds() async throws {
        let counts: TableCounts = try await database.writer.read { (db: Database) throws -> TableCounts in
            TableCounts(
                accounts: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM accounts") ?? 0,
                categories: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories") ?? 0,
                defaultCategories: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories WHERE isDefault = 1") ?? 0,
                transactions: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM transactions") ?? 0,
                recurringMovements: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM recurring_movements WHERE id = '0548d402-cc75-4562-8f1e-44cf4c91e323'") ?? 0,
                loans: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM loans WHERE loanId = '5268f4a2-8141-4265-a697-1292605c5357'") ?? 0,
                loanPayments: try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM loan_payments WHERE paymentId = '59919325-2d70-40e5-871b-2a4b9323aecf'") ?? 0
            )
        }
        let applied: [String] = try await database.writer.read { (db: Database) throws -> [String] in
            try DatabaseMigrator.app.appliedIdentifiers(db).sorted()
        }

        #expect(applied == DatabaseMigrator.app.migrations)
        #expect(counts == TableCounts(accounts: 2, categories: 24, defaultCategories: 23, transactions: 2, recurringMovements: 1, loans: 1, loanPayments: 1))
    }

    @Test("reads the v1 fixture's ledger through the repositories")
    func readsLedgerThroughRepositories() async throws {
        let transactions: GRDBTransactionRepository = GRDBTransactionRepository(database: database, clock: FixedClock(now: Date(timeIntervalSince1970: 0)))
        let accounts: GRDBAccountRepository = GRDBAccountRepository(database: database)
        var augustIterator: any AsyncIteratorProtocol<[Transaction], DomainError> = transactions.transactions(in: try Month(year: 2026, month: 8)).makeAsyncIterator()
        var accountsIterator: any AsyncIteratorProtocol<[Account], DomainError> = accounts.accounts.makeAsyncIterator()

        let august: [Transaction] = try #require(try await augustIterator.next(isolation: #isolation))
        let liveAccounts: [Account] = try #require(try await accountsIterator.next(isolation: #isolation))

        #expect(august == [
            Transaction(
                id: TransactionID("f46c3ef1-e46c-479c-87a7-1562dc321ef3"),
                TransactionInsert(
                    type: .spend,
                    amount: try Amount(cents: 4_590),
                    description: "Comida del gato",
                    occurredAt: try OccurredAt(year: 2026, month: 8, day: 14, hour: 13, minute: 5, second: 30),
                    accountID: AccountID("e8d1035d-4dc3-453d-8eb7-6332f6feeb6b"),
                    categoryID: CategoryID("873130be-2370-429f-b134-ca5e62d43c2c")
                )
            ),
        ])
        #expect(liveAccounts == [
            Account(id: AccountID.seededCash, name: "Efectivo", type: .cash),
            Account(id: AccountID("e8d1035d-4dc3-453d-8eb7-6332f6feeb6b"), name: "BCP", type: .bank),
        ])
    }
}
