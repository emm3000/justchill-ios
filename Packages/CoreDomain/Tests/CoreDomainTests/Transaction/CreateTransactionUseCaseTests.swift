import CoreDomain
import Foundation
import Testing

struct CreateTransactionUseCaseTests {
    private let lima: TimeZone
    private let lateAugustNightInLima: FixedClock
    private let cashAccountID: AccountID = AccountID("cash")

    init() throws {
        lima = try TimeZone.fixture("America/Lima")
        lateAugustNightInLima = try FixedClock("2026-09-01T04:30:00Z")
    }

    @Test("records the movement and returns the id it was stored under")
    func recordsAndReturnsID() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let createTransaction: CreateTransactionUseCase = makeUseCase(repository)
        let lunch: TransactionInsert = try makeInsert(cents: 1_250, occurredAt: OccurredAt(year: 2026, month: 8, day: 31, hour: 13, minute: 0, second: 0))

        let createdID: TransactionID = try await createTransaction(lunch)

        let stored: Transaction = try #require(repository.stored.first)
        #expect(repository.stored.count == 1)
        #expect(stored.id == createdID)
        #expect(stored.amount == lunch.amount)
        #expect(stored.type == .spend)
        #expect(stored.accountID == cashAccountID)
        #expect(stored.occurredAt == lunch.occurredAt)
    }

    @Test("gives every recorded movement its own id")
    func distinctIDs() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let createTransaction: CreateTransactionUseCase = makeUseCase(repository)
        let taxi: TransactionInsert = try makeInsert(cents: 899, occurredAt: OccurredAt(year: 2026, month: 8, day: 31, hour: 9, minute: 0, second: 0))

        let firstID: TransactionID = try await createTransaction(taxi)
        let secondID: TransactionID = try await createTransaction(taxi)

        #expect(firstID != secondID)
    }

    @Test("refuses a zero Amount and records nothing")
    func refusesZeroAmount() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let createTransaction: CreateTransactionUseCase = makeUseCase(repository)
        let nothing: TransactionInsert = try makeInsert(cents: 0, occurredAt: OccurredAt(year: 2026, month: 8, day: 31, hour: 9, minute: 0, second: 0))

        await #expect(throws: DomainError.zeroAmount) {
            try await createTransaction(nothing)
        }
        #expect(repository.stored.isEmpty)
    }

    @Test("refuses a movement dated after today in the injected zone, though UTC is already there")
    func refusesTomorrowInZone() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let createTransaction: CreateTransactionUseCase = makeUseCase(repository)
        let tomorrowInLima: TransactionInsert = try makeInsert(cents: 500, occurredAt: OccurredAt(year: 2026, month: 9, day: 1, hour: 0, minute: 10, second: 0))

        await #expect(throws: DomainError.occurredAfterToday) {
            try await createTransaction(tomorrowInLima)
        }
        #expect(repository.stored.isEmpty)
    }

    @Test("accepts a later hour of today, since only the date is checked")
    func acceptsLaterToday() async throws {
        let repository: InMemoryTransactionRepository = InMemoryTransactionRepository()
        let createTransaction: CreateTransactionUseCase = makeUseCase(repository)
        let lastMinuteToday: TransactionInsert = try makeInsert(cents: 500, occurredAt: OccurredAt(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 0))

        _ = try await createTransaction(lastMinuteToday)

        #expect(repository.stored.count == 1)
    }

    private func makeUseCase(_ repository: InMemoryTransactionRepository) -> CreateTransactionUseCase {
        CreateTransactionUseCase(transactions: repository, clock: lateAugustNightInLima, zone: lima)
    }

    private func makeInsert(cents: Int64, occurredAt: OccurredAt) throws -> TransactionInsert {
        TransactionInsert(
            type: .spend,
            amount: try Amount(cents: cents),
            description: "",
            occurredAt: occurredAt,
            accountID: cashAccountID,
            categoryID: nil
        )
    }
}
