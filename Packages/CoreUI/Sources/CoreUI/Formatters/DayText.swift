import CoreDomain
import Foundation

public struct DayText: Equatable, Sendable {
    private static let weekdays: [String] = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]

    public let text: String

    public init(_ day: Int, of month: Month, today: OccurredAt) {
        let calendar: Calendar = Self.wallClock
        let date: Date? = calendar.date(from: DateComponents(year: month.year, month: month.number, day: day))
        let todayDate: Date? = calendar.date(from: DateComponents(year: today.month.year, month: today.month.number, day: today.day))
        guard let date: Date = date, let todayDate: Date = todayDate else {
            text = String(day)
            return
        }
        text = Self.title(of: date, daysBefore: calendar.dateComponents([.day], from: date, to: todayDate).day, in: calendar)
    }

    private static var wallClock: Calendar {
        var calendar: Calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.gmt
        return calendar
    }

    private static func title(of date: Date, daysBefore: Int?, in calendar: Calendar) -> String {
        switch daysBefore {
        case 0: "Hoy"
        case 1: "Ayer"
        default: "\(weekdays[calendar.component(.weekday, from: date) - 1]) \(calendar.component(.day, from: date))"
        }
    }
}
