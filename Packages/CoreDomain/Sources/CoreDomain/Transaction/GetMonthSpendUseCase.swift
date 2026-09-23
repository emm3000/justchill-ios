public struct GetMonthSpendUseCase: Sendable {
    private let transactions: any TransactionRepository

    public init(transactions: any TransactionRepository) {
        self.transactions = transactions
    }

    public func callAsFunction(_ month: Month) -> any AsyncSequence<Amount, DomainError> {
        spendTotals(of: transactions.transactions(in: month))
    }

    private func spendTotals<MonthTransactions: AsyncSequence<[Transaction], DomainError>>(
        of monthTransactions: MonthTransactions
    ) -> any AsyncSequence<Amount, DomainError> {
        monthTransactions.map { (transactions: [Transaction]) -> Amount in transactions.spendTotal }
    }
}

private extension [Transaction] {
    var spendTotal: Amount {
        filter { (transaction: Transaction) -> Bool in transaction.type == .spend }
            .reduce(Amount.zero) { (total: Amount, transaction: Transaction) -> Amount in total + transaction.amount }
    }
}
