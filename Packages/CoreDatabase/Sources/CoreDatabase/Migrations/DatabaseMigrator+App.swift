import GRDB

extension DatabaseMigrator {
    static let v1: String = "v1-create-ledger-with-defaults"

    static var app: DatabaseMigrator {
        var migrator: DatabaseMigrator = DatabaseMigrator()
        migrator.registerMigration(v1) { (db: Database) throws in
            try db.createV1Tables()
            try db.seedV1Defaults()
        }
        return migrator
    }
}
