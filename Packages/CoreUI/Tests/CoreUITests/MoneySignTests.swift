import Testing
@testable import CoreUI

struct MoneySignTests {
    @Test("income wears success, and only income")
    func tintsOnlyPositive() {
        #expect(MoneySign.positive.tint == Palette.success)
        #expect(MoneySign.unsigned.tint == Palette.textPrimary)
        #expect(MoneySign.negative.tint == Palette.textPrimary)
    }

    @Test("a monochrome amount steps its prefix and decimals down the text ladder")
    func deemphasisesMonochromeMinorParts() {
        #expect(MoneySign.unsigned.minorTint == Palette.textSecondary)
        #expect(MoneySign.negative.minorTint == Palette.textSecondary)
        #expect(MoneySign.positive.minorTint == Palette.success)
    }
}
