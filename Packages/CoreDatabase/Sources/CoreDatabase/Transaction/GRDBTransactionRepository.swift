import CoreDomain
import GRDB

public final class GRDBTransactionRepository: TransactionRepository {
    private let database: AppDatabase
    private let clock: any CoreDomain.Clock

    public init(database: AppDatabase, clock: any CoreDomain.Clock) {
        self.database = database
        self.clock = clock
    }

    public func create(_ transaction: Transaction) async throws(DomainError) {
        let record: TransactionRecord = TransactionRecord(transaction, writtenAt: clock.now.epochMilliseconds)
        do {
            try await database.writer.write { (db: Database) throws in try record.insert(db) }
        } catch {
            throw DomainError(translating: error)
        }
    }

    public func transactions(in month: Month) -> any AsyncSequence<[Transaction], DomainError> {
        let start: String = month.start.databaseText
        let end: String = month.next.start.databaseText
        let observation: ValueObservation<ValueReducers.Fetch<[Transaction]>> = ValueObservation.tracking { (db: Database) throws -> [Transaction] in
            try TransactionRecord.live()
                .filter(TransactionRecord.occurredAt >= start && TransactionRecord.occurredAt < end)
                .fetchAll(db)
                .map { (record: TransactionRecord) throws(DomainError) -> Transaction in try Transaction(record) }
        }
        return DomainFailingSequence(observation.values(in: database.writer))
    }

    public func categorizedTransactions(from start: OccurredAt) -> any AsyncSequence<[Transaction], DomainError> {
        let startText: String = start.databaseText
        let observation: ValueObservation<ValueReducers.Fetch<[Transaction]>> = ValueObservation.tracking { (db: Database) throws -> [Transaction] in
            try TransactionRecord.live()
                .filter(TransactionRecord.occurredAt >= startText)
                .joining(required: TransactionRecord.account.filter(AccountRecord.liveFilter))
                .joining(required: TransactionRecord.category.filter(CategoryRecord.liveFilter))
                .fetchAll(db)
                .map { (record: TransactionRecord) throws(DomainError) -> Transaction in try Transaction(record) }
        }
        return DomainFailingSequence(observation.values(in: database.writer))
    }
}
