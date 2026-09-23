import Testing
import UIKit
@testable import CoreUI

struct FontFaceTests {
    @Test("every bundled face resolves by PostScript name once CoreUI registers it", arguments: FontFace.allCases)
    func resolvesRegisteredFace(face: FontFace) {
        FontFace.registerBundledFaces()

        #expect(UIFont(name: face.postScriptName, size: 17)?.fontName == face.postScriptName)
    }

    @Test("ships every face with its OFL license beside it")
    func shipsLicenses() {
        let licenseNames: [String] = ["Inter-OFL", "IBMPlexMono-OFL"]

        #expect(licenseNames.allSatisfy { FontFace.bundle.url(forResource: $0, withExtension: "txt", subdirectory: "Fonts") != nil })
    }
}
