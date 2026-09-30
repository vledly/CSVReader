import SwiftUI

struct IssuesView<ViewModel: Store<IssuesViewState, IssuesInput>>: View {
    @State private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state.status {
            case .initial:
                ProgressView()
            case .ready:
                ContentUnavailableView(
                    "No CSV selected",
                    systemImage: "tablecells"
                )
            }
        }
        .navigationTitle("CSV Reader")
        .task {
            await viewModel.trigger(.viewDidAppear)
        }
    }
}

#Preview {
    NavigationStack {
        IssuesAssembly.makeView()
    }
}
