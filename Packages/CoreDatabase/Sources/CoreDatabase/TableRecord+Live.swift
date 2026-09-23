import GRDB

extension TableRecord {
    static var liveFilter: SQLExpression {
        Column("deletedAt") == nil
    }

    static func live() -> QueryInterfaceRequest<Self> {
        filter(liveFilter)
    }
}
