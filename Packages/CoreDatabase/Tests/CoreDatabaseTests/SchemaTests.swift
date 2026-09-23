@testable import CoreDatabase
import Foundation
import GRDB
import Testing

struct SchemaTests {
    private struct CategoryTypeKey: Hashable {
        let table: String
        let from: String
        let to: String
        let onDelete: String
    }

    private let directory: TemporaryDirectory
    private let database: AppDatabase

    init() throws {
        directory = try TemporaryDirectory()
        database = try AppDatabase.open(at: directory.databaseURL)
    }

    @Test("migrates a new file to head through exactly one migration, v1")
    func appliesOneMigration() throws {
        let applied: [String] = try database.writer.read { (db: Database) throws -> [String] in
            try DatabaseMigrator.app.appliedIdentifiers(db).sorted()
        }

        #expect(DatabaseMigrator.app.migrations == ["v1-create-ledger-with-defaults"])
        #expect(applied == ["v1-create-ledger-with-defaults"])
    }

    @Test("creates the six tables, each with userId, deletedAt and a Pending syncState")
    func createsSixTablesWithSyncColumns() throws {
        let tables: [String] = ["accounts", "categories", "transactions", "recurring_movements", "loans", "loan_payments"]

        let syncColumns: [String: [String: String?]] = try database.writer.read { (db: Database) throws -> [String: [String: String?]] in
            try Dictionary(uniqueKeysWithValues: tables.map { (table: String) throws -> (String, [String: String?]) in
                let columns: [ColumnInfo] = try db.columns(in: table)
                let defaults: [String: String?] = Dictionary(uniqueKeysWithValues: columns
                    .filter { (column: ColumnInfo) -> Bool in ["userId", "deletedAt", "syncState"].contains(column.name) }
                    .map { (column: ColumnInfo) -> (String, String?) in (column.name, column.defaultValueSQL) })
                return (table, defaults)
            })
        }

        let expected: [String: String?] = ["userId": nil, "deletedAt": nil, "syncState": "'Pending'"]
        #expect(syncColumns == Dictionary(uniqueKeysWithValues: tables.map { (table: String) -> (String, [String: String?]) in (table, expected) }))
    }

    @Test("keys every movement's (categoryId, type) to categories(categoryId, categoryType) with no ON DELETE")
    func keysMovementsToCategoryType() throws {
        let keys: Set<CategoryTypeKey> = try database.writer.read { (db: Database) throws -> Set<CategoryTypeKey> in
            try Set(["transactions", "recurring_movements"].flatMap { (table: String) throws -> [CategoryTypeKey] in
                try Row.fetchAll(db, sql: "SELECT * FROM pragma_foreign_key_list(?) WHERE \"table\" = 'categories'", arguments: [table])
                    .map { (row: Row) -> CategoryTypeKey in
                        CategoryTypeKey(table: table, from: row["from"], to: row["to"], onDelete: row["on_delete"])
                    }
            })
        }

        #expect(keys == [
            CategoryTypeKey(table: "transactions", from: "categoryId", to: "categoryId", onDelete: "NO ACTION"),
            CategoryTypeKey(table: "transactions", from: "type", to: "categoryType", onDelete: "NO ACTION"),
            CategoryTypeKey(table: "recurring_movements", from: "categoryId", to: "categoryId", onDelete: "NO ACTION"),
            CategoryTypeKey(table: "recurring_movements", from: "type", to: "categoryType", onDelete: "NO ACTION"),
        ])
    }

    @Test("indexes categories(categoryId, categoryType) as UNIQUE, the parent the composite key needs")
    func indexesCategoryTypeAsUnique() throws {
        let uniqueIndexColumns: [[String]] = try database.writer.read { (db: Database) throws -> [[String]] in
            try db.indexes(on: "categories")
                .filter { (index: IndexInfo) -> Bool in index.isUnique }
                .map { (index: IndexInfo) -> [String] in index.columns }
        }

        #expect(uniqueIndexColumns.contains(["categoryId", "categoryType"]))
    }
}
