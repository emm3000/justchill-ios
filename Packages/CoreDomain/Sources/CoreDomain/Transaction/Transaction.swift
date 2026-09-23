public struct Transaction: Hashable, Sendable {
    public let id: TransactionID
    public let type: TransactionType
    public let amount: Amount
    public let description: String
    public let occurredAt: OccurredAt
    public let accountID: AccountID
    public let categoryID: CategoryID?

    public init(id: TransactionID, _ insert: TransactionInsert) {
        self.id = id
        type = insert.type
        amount = insert.amount
        description = insert.description
        occurredAt = insert.occurredAt
        accountID = insert.accountID
        categoryID = insert.categoryID
    }
}
