import CoreDomain
import Foundation
import GRDB

public struct AppDatabase: Sendable {
    let writer: any DatabaseWriter

    public static func open(at url: URL) throws(DomainError) -> AppDatabase {
        do {
            let pool: DatabasePool = try DatabasePool(path: url.path(percentEncoded: false))
            try DatabaseMigrator.app.migrate(pool)
            return AppDatabase(writer: pool)
        } catch {
            throw DomainError.storageFailure
        }
    }
}
