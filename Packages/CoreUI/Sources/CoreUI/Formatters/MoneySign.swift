import SwiftUI

public enum MoneySign: Sendable {
    case unsigned
    case positive
    case negative

    public var tint: Color {
        switch self {
        case .positive: Palette.success
        case .unsigned, .negative: Palette.textPrimary
        }
    }

    public var minorTint: Color {
        switch self {
        case .positive: Palette.success
        case .unsigned, .negative: Palette.textSecondary
        }
    }

    var symbol: String {
        switch self {
        case .unsigned: ""
        case .positive: "+"
        case .negative: "\u{2212}"
        }
    }

    var spokenWord: String? {
        switch self {
        case .unsigned: nil
        case .positive: "más"
        case .negative: "menos"
        }
    }
}
