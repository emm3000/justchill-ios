import CoreUI
import SwiftUI

public struct AmountPadScreen: View {
    @State private var model: AmountPadModel
    private let onOpenMonth: () -> Void

    public init(model: AmountPadModel, onOpenMonth: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onOpenMonth = onOpenMonth
    }

    public var body: some View {
        AmountPadContent(
            amount: model.amount,
            type: model.type,
            accountName: model.account?.name,
            monthSpend: model.monthSpend,
            canSave: model.canSave,
            savedTransactionID: model.savedTransactionID,
            failure: model.failure,
            onKey: press,
            onSave: { Task { await model.save() } },
            onDismissFailure: model.dismissFailure,
            onOpenMonth: onOpenMonth
        )
        .task { await model.observe() }
    }

    private func press(_ key: KeypadKey) {
        switch key {
        case .decimalSeparator:
            model.enterDecimalSeparator()
        case .delete:
            model.deleteLast()
        case .toggleSign:
            model.toggleType()
        case .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine:
            guard let digit: Int = key.digit else { return }
            model.enter(digit: digit)
        }
    }
}
