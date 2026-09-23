public enum KeypadKey: Hashable, Sendable, CaseIterable {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case zero
    case decimalSeparator
    case delete
    case toggleSign

    public var digit: Int? {
        switch self {
        case .zero: 0
        case .one: 1
        case .two: 2
        case .three: 3
        case .four: 4
        case .five: 5
        case .six: 6
        case .seven: 7
        case .eight: 8
        case .nine: 9
        case .decimalSeparator, .delete, .toggleSign: nil
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .zero: "cero"
        case .one: "uno"
        case .two: "dos"
        case .three: "tres"
        case .four: "cuatro"
        case .five: "cinco"
        case .six: "seis"
        case .seven: "siete"
        case .eight: "ocho"
        case .nine: "nueve"
        case .decimalSeparator: "punto decimal"
        case .delete: "borrar"
        case .toggleSign: "más o menos"
        }
    }
}
