import SwiftUI

@main
struct CSVReaderApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                IssuesAssembly.makeView()
            }
        }
    }
}
