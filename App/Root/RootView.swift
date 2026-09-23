import FeatureTransaction
import SwiftUI

struct RootView: View {
    let container: AppContainer

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            AmountPadScreen(model: container.makeAmountPadModel())
                .navigationDestination(for: Route.self, destination: destination)
        }
    }

    private func destination(for route: Route) -> Never {
        switch route {}
    }
}
