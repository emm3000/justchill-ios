import CoreText
import Foundation

enum FontFace: CaseIterable, Sendable {
    case interRegular
    case interSemiBold
    case plexMonoRegular

    static let bundle: Bundle = Bundle.module

    private static let fontsDirectory: String = "Fonts"
    private static let fileExtension: String = "ttf"
    private static let registration: Void = registerEachFace()

    var postScriptName: String {
        switch self {
        case .interRegular: "Inter-Regular"
        case .interSemiBold: "Inter-SemiBold"
        case .plexMonoRegular: "IBMPlexMono"
        }
    }

    private var fileName: String {
        switch self {
        case .interRegular: "Inter-Regular"
        case .interSemiBold: "Inter-SemiBold"
        case .plexMonoRegular: "IBMPlexMono-Regular"
        }
    }

    var isMonospaced: Bool {
        self == .plexMonoRegular
    }

    static func registerBundledFaces() {
        registration
    }

    private static func registerEachFace() {
        for face in allCases {
            guard let url: URL = bundle.url(forResource: face.fileName, withExtension: fileExtension, subdirectory: fontsDirectory) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
