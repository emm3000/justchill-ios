import CoreDomain
import CoreUI
import Testing

struct DomainErrorMessageTests {
    @Test("tells the reader, in tú, that storage failed and to try again")
    func storageFailureCopy() {
        #expect(DomainError.storageFailure.message == "No se pudo leer ni guardar en este iPhone. Inténtalo de nuevo.")
    }

    @Test("gives every failure its own message")
    func distinctMessages() {
        let failures: [DomainError] = [
            .negativeAmount(cents: -1),
            .zeroAmount,
            .occurredAfterToday,
            .impossibleOccurredAt,
            .impossibleMonth(year: 2026, month: 13),
            .storageFailure,
        ]

        let messages: Set<String> = Set(failures.map { (failure: DomainError) -> String in failure.message })

        #expect(messages.count == failures.count)
    }
}
