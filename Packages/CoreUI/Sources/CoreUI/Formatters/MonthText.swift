import CoreDomain

public struct MonthText: Equatable, Sendable {
    private static let names: [String] = [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
    ]

    public let text: String

    public init(_ month: Month) {
        text = "\(Self.names[month.number - 1]) \(month.year)"
    }
}
