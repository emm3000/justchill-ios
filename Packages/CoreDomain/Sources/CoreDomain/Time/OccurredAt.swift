import Foundation

public struct OccurredAt: Hashable, Sendable {
    public let month: Month
    public let day: Int
    public let hour: Int
    public let minute: Int
    public let second: Int

    public init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) throws(DomainError) {
        let components: DateComponents = DateComponents(
            calendar: Calendar.wallClock(in: .gmt),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard components.isValidDate else { throw DomainError.impossibleOccurredAt }
        self.init(month: Month(validYear: year, validNumber: month), day: day, hour: hour, minute: minute, second: second)
    }

    public init(_ instant: Date, in zone: TimeZone) {
        let calendar: Calendar = Calendar.wallClock(in: zone)
        self.init(
            month: Month(
                validYear: calendar.component(.year, from: instant),
                validNumber: calendar.component(.month, from: instant)
            ),
            day: calendar.component(.day, from: instant),
            hour: calendar.component(.hour, from: instant),
            minute: calendar.component(.minute, from: instant),
            second: calendar.component(.second, from: instant)
        )
    }

    init(month: Month, day: Int, hour: Int, minute: Int, second: Int) {
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    public func isOnLaterDay(than other: OccurredAt) -> Bool {
        (month.year, month.number, day) > (other.month.year, other.month.number, other.day)
    }
}

extension OccurredAt: Comparable {
    public static func < (lhs: OccurredAt, rhs: OccurredAt) -> Bool {
        (lhs.month.year, lhs.month.number, lhs.day, lhs.hour, lhs.minute, lhs.second)
            < (rhs.month.year, rhs.month.number, rhs.day, rhs.hour, rhs.minute, rhs.second)
    }
}

extension Calendar {
    static func wallClock(in zone: TimeZone) -> Calendar {
        var calendar: Calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }
}
