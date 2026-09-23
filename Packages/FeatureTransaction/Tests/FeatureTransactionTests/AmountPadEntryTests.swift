import CoreDomain
import CoreTesting
import FeatureTransaction
import Testing

@Suite(.timeLimit(.minutes(1)))
struct AmountPadEntryTests {
    private let fixture: AmountPadFixture

    init() throws {
        fixture = try AmountPadFixture()
    }

    @Test("ignores a third decimal")
    func ignoresThirdDecimal() throws {
        let model: AmountPadModel = fixture.makeModel(transactions: InMemoryTransactionRepository())

        model.enter(digit: 1)
        model.enterDecimalSeparator()
        model.enter(digit: 2)
        model.enter(digit: 5)
        model.enter(digit: 9)

        #expect(model.amount == (try Amount(cents: 125)))
    }

    @Test("ignores a second decimal separator")
    func ignoresSecondSeparator() throws {
        let model: AmountPadModel = fixture.makeModel(transactions: InMemoryTransactionRepository())

        model.enter(digit: 1)
        model.enterDecimalSeparator()
        model.enter(digit: 2)
        model.enterDecimalSeparator()
        model.enter(digit: 5)

        #expect(model.amount == (try Amount(cents: 125)))
    }

    @Test("deletes the last key typed, the separator included")
    func deletesLastKey() throws {
        let model: AmountPadModel = fixture.makeModel(transactions: InMemoryTransactionRepository())

        model.enter(digit: 1)
        model.enter(digit: 2)
        model.enterDecimalSeparator()
        model.enter(digit: 5)
        model.deleteLast()
        model.deleteLast()
        model.deleteLast()
        model.enter(digit: 7)

        #expect(model.amount == (try Amount(cents: 1_700)))
    }

    @Test("ignores a digit that would overflow the Amount")
    func ignoresOverflowingDigit() throws {
        let model: AmountPadModel = fixture.makeModel(transactions: InMemoryTransactionRepository())

        for _ in 1...20 {
            model.enter(digit: 9)
        }

        #expect(model.amount == (try Amount(cents: 999_999_999_999_999_900)))
    }
}
