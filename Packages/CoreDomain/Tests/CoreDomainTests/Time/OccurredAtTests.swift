import CoreDomain
import Foundation
import Testing

struct OccurredAtTests {
    @Test("reads an instant as the wall-clock time in the given zone")
    func readsInstantInZone() throws {
        let lima: TimeZone = try #require(TimeZone(identifier: "America/Lima"))
        let instant: Date = try #require(ISO8601DateFormatter().date(from: "2026-09-01T04:30:00Z"))

        let occurredAt: OccurredAt = OccurredAt(instant, in: lima)

        #expect(occurredAt == (try OccurredAt(year: 2026, month: 8, day: 31, hour: 23, minute: 30, second: 0)))
    }

    @Test("falls in the Month of its wall-clock date, not of the instant in UTC")
    func fallsInLocalMonth() throws {
        let lima: TimeZone = try #require(TimeZone(identifier: "America/Lima"))
        let instant: Date = try #require(ISO8601DateFormatter().date(from: "2026-09-01T04:30:00Z"))

        let occurredAt: OccurredAt = OccurredAt(instant, in: lima)

        #expect(occurredAt.month == (try Month(year: 2026, month: 8)))
    }

    @Test("refuses a date the calendar does not have")
    func refusesImpossibleDate() {
        #expect(throws: DomainError.impossibleOccurredAt) {
            try OccurredAt(year: 2026, month: 2, day: 30, hour: 12, minute: 0, second: 0)
        }
    }

    @Test("refuses a time of day the clock does not have")
    func refusesImpossibleTime() {
        #expect(throws: DomainError.impossibleOccurredAt) {
            try OccurredAt(year: 2026, month: 2, day: 3, hour: 24, minute: 0, second: 0)
        }
    }

    @Test("orders by date and then by time of day")
    func ordersChronologically() throws {
        let lateOnMonday: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 21, hour: 23, minute: 59, second: 59)
        let earlyOnTuesday: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 22, hour: 0, minute: 0, second: 0)

        #expect(lateOnMonday < earlyOnTuesday)
    }

    @Test("is on a later day only when its date passes the other's date")
    func comparesDays() throws {
        let morning: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 22, hour: 8, minute: 0, second: 0)
        let night: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 22, hour: 23, minute: 0, second: 0)
        let nextMorning: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 23, hour: 0, minute: 0, second: 1)

        #expect(!night.isOnLaterDay(than: morning))
        #expect(nextMorning.isOnLaterDay(than: night))
    }
}
