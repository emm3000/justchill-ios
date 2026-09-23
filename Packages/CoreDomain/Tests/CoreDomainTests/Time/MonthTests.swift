import CoreDomain
import Testing

struct MonthTests {
    @Test("starts at midnight on its first day")
    func startsOnFirstDay() throws {
        let august: Month = try Month(year: 2026, month: 8)

        #expect(august.start == (try OccurredAt(year: 2026, month: 8, day: 1, hour: 0, minute: 0, second: 0)))
    }

    @Test("knows the next Month's start, across the year boundary")
    func nextStartCrossesYear() throws {
        let december: Month = try Month(year: 2026, month: 12)

        #expect(december.next == (try Month(year: 2027, month: 1)))
        #expect(december.next.start == (try OccurredAt(year: 2027, month: 1, day: 1, hour: 0, minute: 0, second: 0)))
    }

    @Test("contains its last second and not the next Month's first")
    func containsItsOwnRange() throws {
        let august: Month = try Month(year: 2026, month: 8)
        let lastSecond: OccurredAt = try OccurredAt(year: 2026, month: 8, day: 31, hour: 23, minute: 59, second: 59)

        #expect(lastSecond.month == august)
        #expect(august.next.start.month != august)
    }

    @Test("refuses a month the calendar does not have")
    func refusesImpossibleMonth() {
        #expect(throws: DomainError.impossibleMonth(year: 2026, month: 13)) {
            try Month(year: 2026, month: 13)
        }
    }
}
