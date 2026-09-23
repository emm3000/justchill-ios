@testable import CoreDatabase
import Foundation
import GRDB
import Testing

struct SeedTests {
    private struct SeededCategory: Hashable {
        let name: String
        let icon: String
        let color: String
        let categoryType: String
    }

    private let androidDefaults: Set<SeededCategory> = [
        SeededCategory(name: "Supermercado", icon: "groceries", color: "green", categoryType: "Spend"),
        SeededCategory(name: "Restaurantes", icon: "food", color: "orange", categoryType: "Spend"),
        SeededCategory(name: "Comida rápida", icon: "fast_food", color: "red", categoryType: "Spend"),
        SeededCategory(name: "Café", icon: "coffee", color: "brown", categoryType: "Spend"),
        SeededCategory(name: "Bar", icon: "bar", color: "purple", categoryType: "Spend"),
        SeededCategory(name: "Transporte", icon: "car", color: "blue", categoryType: "Spend"),
        SeededCategory(name: "Taxi", icon: "taxi", color: "yellow", categoryType: "Spend"),
        SeededCategory(name: "Transporte público", icon: "bus", color: "teal", categoryType: "Spend"),
        SeededCategory(name: "Gasolina", icon: "fuel", color: "orange", categoryType: "Spend"),
        SeededCategory(name: "Estacionamiento", icon: "parking", color: "gray", categoryType: "Spend"),
        SeededCategory(name: "Alquiler", icon: "rent", color: "purple", categoryType: "Spend"),
        SeededCategory(name: "Servicios básicos", icon: "utilities", color: "yellow", categoryType: "Spend"),
        SeededCategory(name: "Internet", icon: "internet", color: "blue", categoryType: "Spend"),
        SeededCategory(name: "Reparaciones del hogar", icon: "repairs", color: "brown", categoryType: "Spend"),
        SeededCategory(name: "Limpieza", icon: "cleaning", color: "teal", categoryType: "Spend"),
        SeededCategory(name: "Tarjeta de crédito", icon: "credit_card", color: "red", categoryType: "Spend"),
        SeededCategory(name: "Sueldo", icon: "salary", color: "green", categoryType: "Income"),
        SeededCategory(name: "Freelance", icon: "freelance", color: "blue", categoryType: "Income"),
        SeededCategory(name: "Inversiones", icon: "investment", color: "purple", categoryType: "Income"),
        SeededCategory(name: "Ahorros", icon: "savings", color: "teal", categoryType: "Income"),
        SeededCategory(name: "Ventas", icon: "shopping", color: "blue", categoryType: "Income"),
        SeededCategory(name: "Propinas", icon: "tips", color: "yellow", categoryType: "Income"),
        SeededCategory(name: "Otros", icon: "wallet", color: "gray", categoryType: "Income"),
    ]

    @Test("seeds the 23 Android Default categories, 16 Spend and 7 Income")
    func seedsDefaultCategories() throws {
        let directory: TemporaryDirectory = try TemporaryDirectory()
        let database: AppDatabase = try AppDatabase.open(at: directory.databaseURL)

        let rows: [Row] = try database.writer.read { (db: Database) throws -> [Row] in
            try Row.fetchAll(db, sql: "SELECT name, icon, color, categoryType, isDefault FROM categories")
        }

        let seeded: [SeededCategory] = rows.map { (row: Row) -> SeededCategory in
            SeededCategory(name: row["name"], icon: row["icon"], color: row["color"], categoryType: row["categoryType"])
        }
        #expect(seeded.count == 23)
        #expect(Set(seeded) == androidDefaults)
        #expect(rows.allSatisfy { (row: Row) -> Bool in row["isDefault"] == 1 })
    }

    @Test("seeds one live Cash Account named Efectivo in PEN")
    func seedsCashAccount() throws {
        let directory: TemporaryDirectory = try TemporaryDirectory()
        let database: AppDatabase = try AppDatabase.open(at: directory.databaseURL)

        let rows: [Row] = try database.writer.read { (db: Database) throws -> [Row] in
            try Row.fetchAll(db, sql: "SELECT name, type, currency, deletedAt FROM accounts")
        }

        let account: Row = try #require(rows.first)
        #expect(rows.count == 1)
        #expect(account["name"] == "Efectivo")
        #expect(account["type"] == "Cash")
        #expect(account["currency"] == "PEN")
        #expect(account["deletedAt"] == nil as Int64?)
    }

    @Test("gives every seeded row a lowercase UUID id and one fixed epoch-ms stamp")
    func seedsLowercaseIDs() throws {
        let directory: TemporaryDirectory = try TemporaryDirectory()
        let database: AppDatabase = try AppDatabase.open(at: directory.databaseURL)

        let rows: [Row] = try database.writer.read { (db: Database) throws -> [Row] in
            try Row.fetchAll(
                db,
                sql: """
                SELECT categoryId AS id, createdAt, updatedAt, syncState FROM categories
                UNION ALL
                SELECT accountId AS id, createdAt, updatedAt, syncState FROM accounts
                """
            )
        }

        let ids: [String] = rows.map { (row: Row) -> String in row["id"] }
        let stamps: Set<Int64> = Set(rows.flatMap { (row: Row) -> [Int64] in [row["createdAt"], row["updatedAt"]] })
        #expect(ids.allSatisfy { (id: String) -> Bool in UUID(uuidString: id) != nil && id == id.lowercased() })
        #expect(Set(ids).count == 24)
        #expect(stamps.count == 1)
        #expect(rows.allSatisfy { (row: Row) -> Bool in row["syncState"] == "Pending" })
    }
}
