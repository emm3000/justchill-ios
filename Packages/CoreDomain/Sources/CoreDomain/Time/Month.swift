public struct Month: Hashable, Sendable {
    private static let numbersInYear: ClosedRange<Int> = 1...12

    public let year: Int
    public let number: Int

    public init(year: Int, month: Int) throws(DomainError) {
        guard Month.numbersInYear.contains(month) else { throw DomainError.impossibleMonth(year: year, month: month) }
        self.init(validYear: year, validNumber: month)
    }

    init(validYear: Int, validNumber: Int) {
        year = validYear
        number = validNumber
    }

    public var start: OccurredAt {
        OccurredAt(month: self, day: 1, hour: 0, minute: 0, second: 0)
    }

    public var next: Month {
        guard number < Month.numbersInYear.upperBound else {
            return Month(validYear: year + 1, validNumber: Month.numbersInYear.lowerBound)
        }
        return Month(validYear: year, validNumber: number + 1)
    }
}
