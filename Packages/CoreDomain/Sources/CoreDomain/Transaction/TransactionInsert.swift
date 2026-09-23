public struct TransactionInsert: Hashable, Sendable {
    public let type: TransactionType
    public let amount: Amount
    public let description: String
    public let occurredAt: OccurredAt
    public let accountID: AccountID
    public let categoryID: CategoryID?

    public init(
        type: TransactionType,
        amount: Amount,
        description: String,
        occurredAt: OccurredAt,
        accountID: AccountID,
        categoryID: CategoryID?
    ) {
        self.type = type
        self.amount = amount
        self.description = description
        self.occurredAt = occurredAt
        self.accountID = accountID
        self.categoryID = categoryID
    }
}
