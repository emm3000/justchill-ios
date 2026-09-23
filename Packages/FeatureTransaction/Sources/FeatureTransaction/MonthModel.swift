import CoreDomain
import Foundation
import Observation

@Observable
public final class MonthModel {
    public let month: Month
    public let today: OccurredAt
    public private(set) var presentation: MonthPresentation?
    public private(set) var failure: DomainError?

    private let transactions: any TransactionRepository

    public init(transactions: any TransactionRepository, clock: any CoreDomain.Clock, zone: TimeZone) {
        let today: OccurredAt = OccurredAt(clock.now, in: zone)
        self.today = today
        month = today.month
        self.transactions = transactions
    }

    public func observe() async {
        do {
            for try await monthTransactions: [Transaction] in transactions.transactions(in: month) {
                presentation = MonthPresentation(monthTransactions)
            }
        } catch {
            guard !Task.isCancelled else { return }
            failure = error
        }
    }

    public func dismissFailure() {
        failure = nil
    }
}
