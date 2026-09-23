import CoreDomain
import Testing

struct AmountTests {
    @Test("holds a quantity of soles in cents")
    func holdsCents() throws {
        let lunch: Amount = try Amount(cents: 1_250)

        #expect(lunch.cents == 1_250)
    }

    @Test("refuses a negative quantity, because the transaction type carries the sign")
    func refusesNegative() {
        #expect(throws: DomainError.negativeAmount(cents: -1)) {
            try Amount(cents: -1)
        }
    }

    @Test("accepts zero as a magnitude")
    func acceptsZero() throws {
        let nothing: Amount = try Amount(cents: 0)

        #expect(nothing == Amount.zero)
    }

    @Test("adds two magnitudes without leaving cents")
    func addsInCents() throws {
        let lunch: Amount = try Amount(cents: 1_250)
        let taxi: Amount = try Amount(cents: 899)

        #expect((lunch + taxi).cents == 2_149)
    }

    @Test("orders by quantity")
    func ordersByQuantity() throws {
        let small: Amount = try Amount(cents: 100)
        let large: Amount = try Amount(cents: 10_000)

        #expect(small < large)
    }
}
