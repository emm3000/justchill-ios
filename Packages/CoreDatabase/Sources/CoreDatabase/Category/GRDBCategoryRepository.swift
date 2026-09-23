import CoreDomain
import GRDB

public final class GRDBCategoryRepository: CategoryRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public var categories: any AsyncSequence<[Category], DomainError> {
        let observation: ValueObservation<ValueReducers.Fetch<[Category]>> = ValueObservation.tracking { (db: Database) throws -> [Category] in
            try CategoryRecord.live()
                .fetchAll(db)
                .map { (record: CategoryRecord) throws(DomainError) -> Category in try Category(record) }
        }
        return DomainFailingSequence(observation.values(in: database.writer))
    }
}
