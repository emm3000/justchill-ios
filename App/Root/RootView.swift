import CoreUI
import SwiftUI

struct RootView: View {
    let container: AppContainer

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            Text(verbatim: "JustChill")
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.background)
                .navigationDestination(for: Route.self, destination: destination)
        }
    }

    private func destination(for route: Route) -> Never {
        switch route {}
    }
}
