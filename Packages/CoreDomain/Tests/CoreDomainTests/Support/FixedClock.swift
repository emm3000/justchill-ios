import CoreDomain
import Foundation

struct FixedClock: CoreDomain.Clock {
    let now: Date

    init(_ iso8601: String) throws {
        guard let instant: Date = ISO8601DateFormatter().date(from: iso8601) else {
            throw FixtureError.unreadableInstant(iso8601)
        }
        now = instant
    }
}

enum FixtureError: Error {
    case unreadableInstant(String)
    case unknownZone(String)
}

extension TimeZone {
    static func fixture(_ identifier: String) throws -> TimeZone {
        guard let zone: TimeZone = TimeZone(identifier: identifier) else { throw FixtureError.unknownZone(identifier) }
        return zone
    }
}
