import CoreDomain
import GRDB

struct AccountRecord: Decodable, FetchableRecord, TableRecord {
    enum CodingKeys: String, CodingKey {
        case accountID = "accountId"
        case name
        case type
    }

    static let databaseTableName: String = "accounts"
    static let createdAt: Column = Column("createdAt")

    let accountID: String
    let name: String
    let type: String
}

extension Account {
    init(_ record: AccountRecord) throws(DomainError) {
        guard let type: AccountType = AccountType(rawValue: record.type) else { throw DomainError.storageFailure }
        self.init(id: AccountID(record.accountID), name: record.name, type: type)
    }
}
