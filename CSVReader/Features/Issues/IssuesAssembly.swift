import SwiftUI

enum IssuesAssembly {
    @MainActor
    static func makeView(dependencies: IssuesDependencies) -> some View {
        IssuesView(
            viewModel: IssuesViewModel(dependencies: dependencies)
        )
    }
}
