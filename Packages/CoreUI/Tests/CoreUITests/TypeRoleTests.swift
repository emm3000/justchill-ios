import Testing
@testable import CoreUI

struct TypeRoleTests {
    @Test("every amount role is monospaced and every other role is not", arguments: TypeRole.allCases)
    func reservesMonoForAmounts(role: TypeRole) {
        let isAmountRole: Bool = String(describing: role).hasPrefix("amount")

        #expect(role.face.isMonospaced == isAmountRole)
    }

    @Test("the hero amount is the largest type in the app")
    func makesHeroLargest() {
        let others: [TypeRole] = TypeRole.allCases.filter { $0 != .amountHero }

        #expect(others.allSatisfy { $0.size < TypeRole.amountHero.size })
    }

    @Test("every bundled face backs at least one role, so no unused weight ships")
    func shipsOnlyUsedFaces() {
        let usedFaces: Set<FontFace> = Set(TypeRole.allCases.map(\.face))

        #expect(usedFaces == Set(FontFace.allCases))
    }
}
