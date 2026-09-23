import CoreDomain
import Foundation

extension OccurredAt {
    private static let databaseTextFormat: String = "%04d-%02d-%02dT%02d:%02d:%02d"
    private static let databaseTextSeparators: Set<Character> = ["-", "T", ":"]
    private static let databaseTextComponentCount: Int = 6

    init(databaseText: String) throws(DomainError) {
        let components: [Int] = databaseText
            .split(whereSeparator: { (character: Character) -> Bool in OccurredAt.databaseTextSeparators.contains(character) })
            .compactMap { (component: Substring) -> Int? in Int(component) }
        guard components.count == OccurredAt.databaseTextComponentCount else { throw DomainError.impossibleOccurredAt }
        try self.init(
            year: components[0],
            month: components[1],
            day: components[2],
            hour: components[3],
            minute: components[4],
            second: components[5]
        )
    }

    var databaseText: String {
        String(format: OccurredAt.databaseTextFormat, month.year, month.number, day, hour, minute, second)
    }
}
