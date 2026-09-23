public enum DomainError: Error, Equatable, Sendable {
    case negativeAmount(cents: Int64)
    case zeroAmount
    case occurredAfterToday
    case impossibleOccurredAt
    case impossibleMonth(year: Int, month: Int)
    case storageFailure
}
