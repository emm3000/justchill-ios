import CoreDomain
import CoreTesting
import FeatureTransaction
import Foundation

struct AmountPadFixture {
    let lima: TimeZone
    let lateAugustNightInLima: FixedClock
    let cashAccount: Account = Account(id: AccountID("cash"), name: "Efectivo", type: .cash)
    let bankAccount: Account = Account(id: AccountID("bank"), name: "Banco", type: .bank)

    init() throws {
        lima = try TimeZone.fixture("America/Lima")
        lateAugustNightInLima = try FixedClock("2026-09-01T04:30:00Z")
    }

    func makeModel(transactions: InMemoryTransactionRepository) -> AmountPadModel {
        makeModel(transactions: transactions, accounts: InMemoryAccountRepository(accounts: [cashAccount, bankAccount]))
    }

    func makeModel(transactions: InMemoryTransactionRepository, accounts: any AccountRepository) -> AmountPadModel {
        AmountPadModel(
            accounts: accounts,
            createTransaction: CreateTransactionUseCase(transactions: transactions, clock: lateAugustNightInLima, zone: lima),
            getMonthSpend: GetMonthSpendUseCase(transactions: transactions),
            clock: lateAugustNightInLima,
            zone: lima
        )
    }

    func makeMarketSpend() throws -> Transaction {
        Transaction(
            id: TransactionID("market"),
            TransactionInsert(
                type: .spend,
                amount: try Amount(cents: 4_000),
                description: "",
                occurredAt: try OccurredAt(year: 2026, month: 8, day: 3, hour: 10, minute: 0, second: 0),
                accountID: cashAccount.id,
                categoryID: nil
            )
        )
    }
}
