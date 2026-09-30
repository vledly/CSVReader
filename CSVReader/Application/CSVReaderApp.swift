import SwiftUI

@main
struct CSVReaderApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                IssuesAssembly.makeView(
                    dependencies: container.issuesDependencies
                )
            }
        }
    }
}
