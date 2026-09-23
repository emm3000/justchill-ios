import CoreDatabase
import CoreDomain
import FeatureTransaction
import Foundation

final class AppContainer {
    private static let databaseFileName: String = "justchill.sqlite"

    private let clock: any CoreDomain.Clock = SystemClock()
    private let zone: TimeZone = TimeZone.current
    private let accounts: any AccountRepository
    private let transactions: any TransactionRepository

    init() throws(DomainError) {
        let database: AppDatabase = try AppDatabase.open(at: Self.makeDatabaseURL())
        accounts = GRDBAccountRepository(database: database)
        transactions = GRDBTransactionRepository(database: database, clock: clock)
    }

    func makeAmountPadModel() -> AmountPadModel {
        AmountPadModel(
            accounts: accounts,
            createTransaction: CreateTransactionUseCase(transactions: transactions, clock: clock, zone: zone),
            getMonthSpend: GetMonthSpendUseCase(transactions: transactions),
            clock: clock,
            zone: zone
        )
    }

    private static func makeDatabaseURL() throws(DomainError) -> URL {
        let directory: URL = URL.applicationSupportDirectory
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw DomainError.storageFailure
        }
        return directory.appending(path: databaseFileName)
    }
}
