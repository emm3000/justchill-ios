import CoreDomain
import SwiftUI

@main
struct JustChillApp: App {
    @State private var launch: Result<AppContainer, DomainError> = Result { () throws(DomainError) -> AppContainer in
        try AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .success(let container):
                RootView(container: container)
            case .failure(let failure):
                LaunchFailureView(failure: failure)
            }
        }
    }
}
