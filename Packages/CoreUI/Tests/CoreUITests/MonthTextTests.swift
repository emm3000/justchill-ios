import CoreDomain
import CoreUI
import Testing

struct MonthTextTests {
    @Test("writes the Month as its capitalised Spanish name and its year", arguments: [
        (1, "Enero 2026"),
        (2, "Febrero 2026"),
        (3, "Marzo 2026"),
        (4, "Abril 2026"),
        (5, "Mayo 2026"),
        (6, "Junio 2026"),
        (7, "Julio 2026"),
        (8, "Agosto 2026"),
        (9, "Septiembre 2026"),
        (10, "Octubre 2026"),
        (11, "Noviembre 2026"),
        (12, "Diciembre 2026"),
    ])
    func namesMonth(number: Int, expected: String) throws {
        let month: Month = try Month(year: 2026, month: number)

        #expect(MonthText(month).text == expected)
    }
}
