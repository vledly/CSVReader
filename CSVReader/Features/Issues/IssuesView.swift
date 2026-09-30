import SwiftUI

struct IssuesView<ViewModel: Store<IssuesViewState, IssuesInput>>: View {
    @State private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state.status {
            case .initial, .loading:
                ProgressView()
            case .content(let content):
                Content(content: content)
            case .failure:
                ContentUnavailableView {
                    Label(
                        .issuesErrorTitle,
                        systemImage: AppIcons.error
                    )
                }
            }
        }
        .navigationTitle(.issuesTitle)
        .task {
            await viewModel.trigger(.viewDidAppear)
        }
    }
}

private extension IssuesView {
    struct Content: View {
        let content: IssuesViewState.Content

        var body: some View {
            if content.items.isEmpty {
                ContentUnavailableView {
                    Label(
                        .issuesEmptyTitle,
                        systemImage: AppIcons.table
                    )
                }
            } else {
                List(content.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)

                        HStack {
                            Text(item.issueCount)
                            Spacer()
                            Text(item.dateOfBirth)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        IssuesAssembly.makeView(
            dependencies: IssuesDependencies(
                issuesService: IssuesService(
                    parser: TabularDataCSVParser()
                ),
                initialFileURL: Bundle.main.url(
                    forResource: "issues",
                    withExtension: "csv"
                )
            )
        )
    }
}
