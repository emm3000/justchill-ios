import CoreDomain
import Foundation

struct SystemClock: CoreDomain.Clock {
    var now: Date {
        Date()
    }
}
