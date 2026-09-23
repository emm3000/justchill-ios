import FeatureTransaction
import SwiftUI

struct RootView: View {
    let container: AppContainer

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            AmountPadScreen(model: container.makeAmountPadModel(), onOpenMonth: { open(.month) })
                .navigationDestination(for: Route.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .month:
            MonthScreen(model: container.makeMonthModel())
        }
    }

    private func open(_ route: Route) {
        guard let index: Int = path.firstIndex(of: route) else {
            path.append(route)
            return
        }
        path.removeLast(path.count - 1 - index)
    }
}
