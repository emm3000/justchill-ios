import SwiftUI

@main
struct JustChillApp: App {
    @State private var container: AppContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
