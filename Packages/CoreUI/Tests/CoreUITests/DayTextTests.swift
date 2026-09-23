import CoreDomain
import CoreUI
import Testing

struct DayTextTests {
    @Test("calls today's day Hoy")
    func namesToday() throws {
        let today: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 22, hour: 23, minute: 10, second: 0)
        let september: Month = try Month(year: 2026, month: 9)

        #expect(DayText(22, of: september, today: today).text == "Hoy")
    }

    @Test("calls the day before today Ayer, across a Month boundary too", arguments: [
        (2026, 9, 21, 2026, 9, 22),
        (2026, 8, 31, 2026, 9, 1),
        (2025, 12, 31, 2026, 1, 1),
    ])
    func namesYesterday(year: Int, month: Int, day: Int, todayYear: Int, todayMonth: Int, todayDay: Int) throws {
        let today: OccurredAt = try OccurredAt(year: todayYear, month: todayMonth, day: todayDay, hour: 0, minute: 5, second: 0)
        let dayMonth: Month = try Month(year: year, month: month)

        #expect(DayText(day, of: dayMonth, today: today).text == "Ayer")
    }

    @Test("writes an older day as its lowercase Spanish weekday and its number", arguments: [
        (20, "domingo 20"),
        (14, "lunes 14"),
        (15, "martes 15"),
        (16, "miércoles 16"),
        (17, "jueves 17"),
        (18, "viernes 18"),
        (19, "sábado 19"),
        (1, "martes 1"),
    ])
    func namesOlderDay(day: Int, expected: String) throws {
        let today: OccurredAt = try OccurredAt(year: 2026, month: 9, day: 22, hour: 12, minute: 0, second: 0)
        let september: Month = try Month(year: 2026, month: 9)

        #expect(DayText(day, of: september, today: today).text == expected)
    }
}
