@testable import CoreDatabase
import CoreDomain
import GRDB
import Testing

struct GRDBCategoryRepositoryTests {
    private let directory: TemporaryDirectory
    private let database: AppDatabase
    private let repository: GRDBCategoryRepository

    init() throws {
        directory = try TemporaryDirectory()
        database = try AppDatabase.open(at: directory.databaseURL)
        repository = GRDBCategoryRepository(database: database)
    }

    @Test("lists the 23 Default categories of both types on a fresh database")
    func listsDefaultCategories() async throws {
        var iterator: any AsyncIteratorProtocol<[Category], DomainError> = repository.categories.makeAsyncIterator()

        let categories: [Category] = try #require(try await iterator.next(isolation: #isolation))

        #expect(categories.count == 23)
        #expect(categories.filter { (category: Category) -> Bool in category.type == .spend }.count == 16)
        #expect(categories.filter { (category: Category) -> Bool in category.type == .income }.count == 7)
    }

    @Test("hides a soft-deleted Category")
    func hidesSoftDeleted() async throws {
        try await database.writer.write { (db: Database) throws in
            try db.execute(sql: "UPDATE categories SET deletedAt = 1790091000250 WHERE categoryId = ?", arguments: [CategoryID.seededGroceries.rawValue])
        }

        var iterator: any AsyncIteratorProtocol<[Category], DomainError> = repository.categories.makeAsyncIterator()
        let categories: [Category] = try #require(try await iterator.next(isolation: #isolation))

        #expect(categories.count == 22)
        #expect(categories.allSatisfy { (category: Category) -> Bool in category.id != .seededGroceries })
    }
}
