import Testing
@testable import CoreUI

struct KeypadKeyTests {
    @Test("every key carries its own Spanish accessibility label")
    func labelsEveryKey() {
        let labels: [String] = KeypadKey.allCases.map(\.accessibilityLabel)

        #expect(Set(labels).count == KeypadKey.allCases.count)
        #expect(KeypadKey.toggleSign.accessibilityLabel == "más o menos")
    }

    @Test("a digit key carries its value and a function key carries none")
    func carriesDigitValue() {
        let digits: [Int] = KeypadKey.allCases.compactMap(\.digit)

        #expect(digits.sorted() == Array(0...9))
        #expect(KeypadKey.seven.digit == 7)
        #expect(KeypadKey.delete.digit == nil)
    }
}
