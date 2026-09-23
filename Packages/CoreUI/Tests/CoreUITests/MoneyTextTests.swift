import CoreDomain
import Testing
@testable import CoreUI

struct MoneyTextTests {
    @Test("writes soles with comma thousands, dot decimals and one space after S/")
    func writesUnsignedAmount() throws {
        let lunch: Amount = try Amount(cents: 123_456)

        #expect(MoneyText(lunch).text == "S/ 1,234.56")
    }

    @Test("puts the plus before the symbol for a positive amount")
    func writesPositiveAmount() throws {
        let salary: Amount = try Amount(cents: 123_456)

        #expect(MoneyText(salary, sign: .positive).text == "+S/ 1,234.56")
    }

    @Test("puts the Unicode minus, never the hyphen, before the symbol for a negative amount")
    func writesNegativeAmount() throws {
        let shortfall: Amount = try Amount(cents: 123_456)
        let text: String = MoneyText(shortfall, sign: .negative).text

        #expect(text == "\u{2212}S/ 1,234.56")
        #expect(!text.contains("-"))
    }

    @Test("always writes two decimals", arguments: [
        (Int64(0), "S/ 0.00"),
        (Int64(5), "S/ 0.05"),
        (Int64(100), "S/ 1.00"),
        (Int64(1_050), "S/ 10.50"),
    ])
    func writesTwoDecimals(cents: Int64, expected: String) throws {
        let amount: Amount = try Amount(cents: cents)

        #expect(MoneyText(amount).text == expected)
    }

    @Test("groups every three integer digits", arguments: [
        (Int64(99_999), "S/ 999.99"),
        (Int64(100_000), "S/ 1,000.00"),
        (Int64(123_456_789), "S/ 1,234,567.89"),
        (Int64(100_000_000_000), "S/ 1,000,000,000.00"),
    ])
    func groupsThousands(cents: Int64, expected: String) throws {
        let amount: Amount = try Amount(cents: cents)

        #expect(MoneyText(amount).text == expected)
    }

    @Test("splits the prefix and the decimals from the integer so a hero can deemphasise them")
    func splitsParts() throws {
        let salary: Amount = try Amount(cents: 123_456)
        let money: MoneyText = MoneyText(salary, sign: .positive)

        #expect(money.prefix == "+S/ ")
        #expect(money.integer == "1,234")
        #expect(money.fraction == ".56")
    }

    @Test("pairs the sign with a word VoiceOver reads", arguments: [
        (MoneySign.unsigned, "1,234.56 soles"),
        (MoneySign.positive, "más 1,234.56 soles"),
        (MoneySign.negative, "menos 1,234.56 soles"),
    ])
    func speaksSign(sign: MoneySign, expected: String) throws {
        let amount: Amount = try Amount(cents: 123_456)

        #expect(MoneyText(amount, sign: sign).spokenText == expected)
    }
}
