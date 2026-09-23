import CoreDomain
import GRDB

struct TransactionRecord: Codable, FetchableRecord, PersistableRecord {
    enum CodingKeys: String, CodingKey {
        case transactionID = "transactionId"
        case type
        case amount
        case description
        case occurredAt
        case categoryID = "categoryId"
        case accountID = "accountId"
        case createdAt
        case updatedAt
    }

    static let databaseTableName: String = "transactions"
    static let occurredAt: Column = Column(CodingKeys.occurredAt)

    let transactionID: String
    let type: String
    let amount: Int64
    let description: String
    let occurredAt: String
    let categoryID: String?
    let accountID: String
    let createdAt: Int64
    let updatedAt: Int64
}

extension TransactionRecord {
    init(_ transaction: Transaction, writtenAt epochMilliseconds: Int64) {
        transactionID = transaction.id.rawValue
        type = transaction.type.rawValue
        amount = transaction.amount.cents
        description = transaction.description
        occurredAt = transaction.occurredAt.databaseText
        categoryID = transaction.categoryID?.rawValue
        accountID = transaction.accountID.rawValue
        createdAt = epochMilliseconds
        updatedAt = epochMilliseconds
    }
}

extension Transaction {
    init(_ record: TransactionRecord) throws(DomainError) {
        guard let type: TransactionType = TransactionType(rawValue: record.type) else { throw DomainError.storageFailure }
        self.init(
            id: TransactionID(record.transactionID),
            TransactionInsert(
                type: type,
                amount: try Amount(cents: record.amount),
                description: record.description,
                occurredAt: try OccurredAt(databaseText: record.occurredAt),
                accountID: AccountID(record.accountID),
                categoryID: record.categoryID.map { (rawValue: String) -> CategoryID in CategoryID(rawValue) }
            )
        )
    }
}
