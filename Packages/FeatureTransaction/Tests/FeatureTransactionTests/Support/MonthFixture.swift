import CoreDomain
import CoreTesting
import FeatureTransaction
import Foundation

struct MonthFixture {
    let lima: TimeZone
    let tuesdayMorningInLima: FixedClock
    let cashAccount: AccountID = AccountID("cash")

    init() throws {
        lima = try TimeZone.fixture("America/Lima")
        tuesdayMorningInLima = try FixedClock("2026-09-22T15:00:00Z")
    }

    func makeModel(transactions: any TransactionRepository) -> MonthModel {
        MonthModel(transactions: transactions, clock: tuesdayMorningInLima, zone: lima)
    }

    func makeTransaction(
        _ id: String,
        _ type: TransactionType,
        cents: Int64,
        day: Int,
        hour: Int = 12,
        description: String = ""
    ) throws -> Transaction {
        Transaction(
            id: TransactionID(id),
            TransactionInsert(
                type: type,
                amount: try Amount(cents: cents),
                description: description,
                occurredAt: try OccurredAt(year: 2026, month: 9, day: day, hour: hour, minute: 0, second: 0),
                accountID: cashAccount,
                categoryID: nil
            )
        )
    }
}
