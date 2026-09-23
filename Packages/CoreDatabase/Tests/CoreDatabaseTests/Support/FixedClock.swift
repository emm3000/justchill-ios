import CoreDomain
import Foundation

struct FixedClock: CoreDomain.Clock {
    let now: Date
}
