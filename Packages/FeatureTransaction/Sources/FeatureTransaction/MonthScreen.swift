import SwiftUI

public struct MonthScreen: View {
    @State private var model: MonthModel

    public init(model: MonthModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        MonthContent(
            month: model.month,
            today: model.today,
            presentation: model.presentation,
            failure: model.failure,
            onDismissFailure: model.dismissFailure
        )
        .task { await model.observe() }
    }
}
