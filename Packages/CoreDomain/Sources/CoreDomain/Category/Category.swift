public struct Category: Hashable, Sendable {
    public let id: CategoryID
    public let name: String
    public let iconID: String
    public let colorID: String
    public let type: CategoryType

    public init(id: CategoryID, name: String, iconID: String, colorID: String, type: CategoryType) {
        self.id = id
        self.name = name
        self.iconID = iconID
        self.colorID = colorID
        self.type = type
    }
}
