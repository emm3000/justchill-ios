@testable import CoreDatabase
import CoreDomain
import GRDB
import Testing

struct GRDBAccountRepositoryTests {
    private let database: AppDatabase
    private let repository: GRDBAccountRepository

    init() throws {
        database = try AppDatabase.open(at: try TemporaryDirectory().databaseURL)
        repository = GRDBAccountRepository(database: database)
    }

    @Test("lists live Accounts oldest createdAt first and leaves soft-deleted ones out")
    func listsLiveAccountsOldestFirst() async throws {
        try await database.writer.write { (db: Database) throws in
            try db.execute(sql: """
                INSERT INTO accounts (accountId, name, type, currency, createdAt, updatedAt, deletedAt) VALUES
                ('bank', 'BCP', 'Bank', 'PEN', 1790040000000, 1790040000000, NULL),
                ('closed', 'Vieja', 'Bank', 'PEN', 1790036000000, 1790036000000, 1790050000000),
                ('wallet', 'Yape', 'Wallet', 'PEN', 1790038000000, 1790038000000, NULL)
                """)
        }
        var iterator: any AsyncIteratorProtocol<[Account], DomainError> = repository.accounts.makeAsyncIterator()

        let accounts: [Account] = try #require(try await iterator.next(isolation: #isolation))

        #expect(accounts == [
            Account(id: AccountID.seededCash, name: "Efectivo", type: .cash),
            Account(id: AccountID("wallet"), name: "Yape", type: .wallet),
            Account(id: AccountID("bank"), name: "BCP", type: .bank),
        ])
    }
}
