import CoreDomain
import GRDB

struct CategoryRecord: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case categoryID = "categoryId"
        case name
        case iconID = "icon"
        case colorID = "color"
        case type = "categoryType"
    }

    static let databaseTableName: String = "categories"

    let categoryID: String
    let name: String
    let iconID: String
    let colorID: String
    let type: String
}

extension Category {
    init(_ record: CategoryRecord) throws(DomainError) {
        guard let type: CategoryType = CategoryType(rawValue: record.type) else { throw DomainError.storageFailure }
        self.init(id: CategoryID(record.categoryID), name: record.name, iconID: record.iconID, colorID: record.colorID, type: type)
    }
}
