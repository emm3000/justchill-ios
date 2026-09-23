public struct FrequentCombo: Hashable, Sendable {
    public let accountID: AccountID
    public let categoryID: CategoryID
    public let type: TransactionType

    public init(accountID: AccountID, categoryID: CategoryID, type: TransactionType) {
        self.accountID = accountID
        self.categoryID = categoryID
        self.type = type
    }
}
