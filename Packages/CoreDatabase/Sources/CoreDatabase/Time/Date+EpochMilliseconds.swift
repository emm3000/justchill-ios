import Foundation

extension Date {
    private static let millisecondsPerSecond: Double = 1_000

    var epochMilliseconds: Int64 {
        Int64((timeIntervalSince1970 * Date.millisecondsPerSecond).rounded(.down))
    }
}
