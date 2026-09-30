import SwiftUI

enum IssuesAssembly {
    @MainActor
    static func makeView() -> some View {
        IssuesView(viewModel: IssuesViewModel())
    }
}
