import CoreDomain
import Foundation
import Observation

@Observable
public final class AmountPadModel {
    public private(set) var type: TransactionType = .spend
    public private(set) var accounts: [Account]?
    public private(set) var monthSpend: Amount?
    public private(set) var savedTransactionID: TransactionID?
    public private(set) var failure: DomainError?
    private var isSaving: Bool = false
    private var entry: AmountEntry = AmountEntry()

    private let accountRepository: any AccountRepository
    private let createTransaction: CreateTransactionUseCase
    private let getMonthSpend: GetMonthSpendUseCase
    private let clock: any CoreDomain.Clock
    private let zone: TimeZone

    public init(
        accounts: any AccountRepository,
        createTransaction: CreateTransactionUseCase,
        getMonthSpend: GetMonthSpendUseCase,
        clock: any CoreDomain.Clock,
        zone: TimeZone
    ) {
        accountRepository = accounts
        self.createTransaction = createTransaction
        self.getMonthSpend = getMonthSpend
        self.clock = clock
        self.zone = zone
    }

    public var amount: Amount {
        entry.amount
    }

    public var account: Account? {
        accounts?.first
    }

    public var canSave: Bool {
        amount != Amount.zero && account != nil && !isSaving
    }

    public func observe() async {
        let month: Month = OccurredAt(clock.now, in: zone).month
        async let accountsFollowed: Void = follow(accountRepository.accounts) { @MainActor (live: [Account]) in self.accounts = live }
        async let monthSpendFollowed: Void = follow(getMonthSpend(month)) { @MainActor (spend: Amount) in self.monthSpend = spend }
        _ = await (accountsFollowed, monthSpendFollowed)
    }

    public func enter(digit: Int) {
        entry = entry.entering(digit: digit)
    }

    public func enterDecimalSeparator() {
        entry = entry.enteringDecimalSeparator()
    }

    public func deleteLast() {
        entry = entry.deletingLast()
    }

    public func toggleType() {
        type = type == .spend ? .income : .spend
    }

    public func save() async {
        guard canSave, let account: Account = account else { return }
        isSaving = true
        defer { isSaving = false }
        let insert: TransactionInsert = TransactionInsert(
            type: type,
            amount: amount,
            description: "",
            occurredAt: OccurredAt(clock.now, in: zone),
            accountID: account.id,
            categoryID: nil
        )
        do {
            savedTransactionID = try await createTransaction(insert)
            entry = AmountEntry()
            type = .spend
        } catch {
            guard !Task.isCancelled else { return }
            failure = error
        }
    }

    public func dismissFailure() {
        failure = nil
    }

    private func follow<Element: Sendable>(
        _ sequence: any AsyncSequence<Element, DomainError>,
        applying apply: @MainActor (Element) -> Void
    ) async {
        do {
            for try await element: Element in sequence {
                apply(element)
            }
        } catch {
            failure = error
        }
    }
}
