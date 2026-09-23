public struct Amount: Hashable, Comparable, Sendable {
    public static let zero: Amount = Amount(validCents: 0)

    public let cents: Int64

    public init(cents: Int64) throws(DomainError) {
        guard cents >= 0 else { throw DomainError.negativeAmount(cents: cents) }
        self.cents = cents
    }

    private init(validCents: Int64) {
        cents = validCents
    }

    public static func + (lhs: Amount, rhs: Amount) -> Amount {
        Amount(validCents: lhs.cents + rhs.cents)
    }

    public static func < (lhs: Amount, rhs: Amount) -> Bool {
        lhs.cents < rhs.cents
    }
}
