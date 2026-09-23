import CoreDomain
import Testing

struct LedgerTypeTests {
    @Test("transaction types keep the schema text Income and Spend")
    func transactionTypeRawValues() {
        let rawValues: [String] = TransactionType.allCases.map(\.rawValue)

        #expect(rawValues == ["Income", "Spend"])
    }

    @Test("category types share the transaction types' schema text, which the composite key compares")
    func categoryTypeRawValues() {
        let rawValues: [String] = CategoryType.allCases.map(\.rawValue)

        #expect(rawValues == ["Income", "Spend"])
    }

    @Test("account types keep their schema text")
    func accountTypeRawValues() {
        let rawValues: [String] = AccountType.allCases.map(\.rawValue)

        #expect(rawValues == ["Bank", "Cash", "CreditCard", "Investment", "Wallet"])
    }
}
