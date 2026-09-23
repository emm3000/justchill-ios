import SwiftUI

public enum Palette {
    public static let background: Color = Color(rgb: 0x000000)
    public static let surface1: Color = Color(rgb: 0x202020)
    public static let surface2: Color = Color(rgb: 0x262626)
    public static let surface3: Color = Color(rgb: 0x2D2D2D)
    public static let border: Color = Color(rgb: 0x2E2E2E)
    public static let borderFocus: Color = Color(rgb: 0x767676)

    public static let textPrimary: Color = Color(rgb: 0xE6E6E6)
    public static let textSecondary: Color = Color(rgb: 0xA8A8A8)
    public static let textTertiary: Color = Color(rgb: 0x767676)
    public static let textDisabled: Color = Color(rgb: 0x4A4A4A)

    public static let success: Color = Color(rgb: 0x6FA876)
    public static let warning: Color = Color(rgb: 0xB3935A)
    public static let danger: Color = Color(rgb: 0xCB6A5C)
    public static let info: Color = Color(rgb: 0x7C8B99)
    public static let positiveMuted: Color = Color(rgb: 0x6FA876, opacity: 0.14)
    public static let negativeMuted: Color = Color(rgb: 0xCB6A5C, opacity: 0.14)

    public static let categorySlate: Color = Color(rgb: 0x7C8B99)
    public static let categorySage: Color = Color(rgb: 0x7FA075)
    public static let categoryTerracotta: Color = Color(rgb: 0xC97A5C)
    public static let categoryMauve: Color = Color(rgb: 0x9C7A95)
    public static let categoryOchre: Color = Color(rgb: 0xB3935A)
    public static let categoryGraphite: Color = Color(rgb: 0x7A7A7A)
}

public enum Spacing {
    public static let hairline: CGFloat = 1
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20
    public static let s6: CGFloat = 24
    public static let s8: CGFloat = 32
    public static let s10: CGFloat = 40
    public static let s12: CGFloat = 48
    public static let s16: CGFloat = 64
    public static let touchTarget: CGFloat = 48
}

public enum Radius {
    public static let xs: CGFloat = 8
    public static let s: CGFloat = 10
    public static let m: CGFloat = 12
    public static let l: CGFloat = 14
    public static let xl: CGFloat = 16
    public static let xxl: CGFloat = 20
}

public enum Typography {
    public static let body: Font = Font.body
    public static let label: Font = Font.headline
    public static let caption: Font = Font.caption
    public static let amountHero: Font = Font.system(.largeTitle, design: .monospaced).monospacedDigit()
}

private extension Color {
    init(rgb: UInt32, opacity: Double = 1) {
        let red: Double = Double((rgb >> 16) & 0xFF) / 255
        let green: Double = Double((rgb >> 8) & 0xFF) / 255
        let blue: Double = Double(rgb & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
