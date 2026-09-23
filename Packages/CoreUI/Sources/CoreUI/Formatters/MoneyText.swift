import CoreDomain

public struct MoneyText: Equatable, Sendable {
    private static let symbol: String = "S/ "
    private static let groupSeparator: String = ","
    private static let decimalSeparator: String = "."
    private static let groupSize: Int = 3
    private static let centsPerSol: Int64 = 100

    public let sign: MoneySign
    public let prefix: String
    public let integer: String
    public let fraction: String

    public init(_ amount: Amount, sign: MoneySign = .unsigned) {
        let soles: Int64 = amount.cents / Self.centsPerSol
        let cents: Int64 = amount.cents % Self.centsPerSol
        self.sign = sign
        prefix = sign.symbol + Self.symbol
        integer = Self.grouped(String(soles))
        fraction = Self.decimalSeparator + (cents < 10 ? "0" : "") + String(cents)
    }

    public var text: String {
        prefix + integer + fraction
    }

    public var spokenText: String {
        let number: String = "\(integer)\(fraction) soles"
        guard let word: String = sign.spokenWord else { return number }
        return "\(word) \(number)"
    }

    private static func grouped(_ digits: String) -> String {
        let characters: [Character] = Array(digits)
        let leadingCount: Int = characters.count % groupSize
        let groups: [String] = stride(from: leadingCount, to: characters.count, by: groupSize).map { start in
            String(characters[start..<(start + groupSize)])
        }
        let leading: [String] = leadingCount > 0 ? [String(characters[..<leadingCount])] : []
        return (leading + groups).joined(separator: groupSeparator)
    }
}
