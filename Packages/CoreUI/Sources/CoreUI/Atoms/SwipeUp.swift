import SwiftUI

extension View {
    public func onSwipeUp(perform action: @escaping () -> Void) -> some View {
        modifier(SwipeUp(action: action))
    }
}

private struct SwipeUp: ViewModifier {
    private static let minimumTravel: CGFloat = Spacing.touchTarget

    let action: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture().onEnded { (drag: DragGesture.Value) in
                guard Self.isSwipeUp(drag.translation) else { return }
                action()
            }
        )
    }

    private static func isSwipeUp(_ translation: CGSize) -> Bool {
        -translation.height >= minimumTravel && abs(translation.height) > abs(translation.width)
    }
}
