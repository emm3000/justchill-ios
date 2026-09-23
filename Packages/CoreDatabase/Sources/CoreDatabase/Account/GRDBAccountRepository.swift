import CoreDomain
import GRDB

public final class GRDBAccountRepository: AccountRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public var accounts: any AsyncSequence<[Account], DomainError> {
        let observation: ValueObservation<ValueReducers.Fetch<[Account]>> = ValueObservation.tracking { (db: Database) throws -> [Account] in
            try AccountRecord.live()
                .order(AccountRecord.createdAt)
                .fetchAll(db)
                .map { (record: AccountRecord) throws(DomainError) -> Account in try Account(record) }
        }
        return DomainFailingSequence(observation.values(in: database.writer))
    }
}
