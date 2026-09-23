import CoreDomain
import Foundation

struct AmountEntry: Hashable, Sendable {
    private static let fractionLength: Int = 2

    private var integerDigits: String = ""
    private var fractionDigits: String?

    var amount: Amount {
        guard let cents: Int64 = cents, let amount: Amount = try? Amount(cents: cents) else { return Amount.zero }
        return amount
    }

    func entering(digit: Int) -> AmountEntry {
        let next: AmountEntry = fractionDigits == nil ? enteringInteger(digit: digit) : enteringFraction(digit: digit)
        return next.cents == nil ? self : next
    }

    func enteringDecimalSeparator() -> AmountEntry {
        var next: AmountEntry = self
        next.fractionDigits = fractionDigits ?? ""
        return next
    }

    func deletingLast() -> AmountEntry {
        var next: AmountEntry = self
        if let fractionDigits {
            next.fractionDigits = fractionDigits.isEmpty ? nil : String(fractionDigits.dropLast())
        } else {
            next.integerDigits = String(integerDigits.dropLast())
        }
        return next
    }

    private func enteringInteger(digit: Int) -> AmountEntry {
        var next: AmountEntry = self
        next.integerDigits = integerDigits + String(digit)
        return next
    }

    private func enteringFraction(digit: Int) -> AmountEntry {
        let fraction: String = fractionDigits ?? ""
        guard fraction.count < Self.fractionLength else { return self }
        var next: AmountEntry = self
        next.fractionDigits = fraction + String(digit)
        return next
    }

    private var cents: Int64? {
        let fraction: String = (fractionDigits ?? "").padding(toLength: Self.fractionLength, withPad: "0", startingAt: 0)
        return Int64(integerDigits + fraction)
    }
}
