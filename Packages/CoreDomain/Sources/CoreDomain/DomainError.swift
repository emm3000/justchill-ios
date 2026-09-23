public enum DomainError: Error, Equatable, Sendable {
    case negativeAmount(cents: Int64)
}
