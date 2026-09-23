import GRDB

extension TableRecord {
    static func live() -> QueryInterfaceRequest<Self> {
        filter(Column("deletedAt") == nil)
    }
}
