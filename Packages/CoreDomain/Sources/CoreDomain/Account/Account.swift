public struct Account: Hashable, Sendable {
    public let id: AccountID
    public let name: String
    public let type: AccountType

    public init(id: AccountID, name: String, type: AccountType) {
        self.id = id
        self.name = name
        self.type = type
    }
}
