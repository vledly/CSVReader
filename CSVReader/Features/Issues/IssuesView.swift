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
                Content(
                    content: content,
                    loadNextPageAction: {
                        send(.loadNextPage)
                    },
                    retryNextPageAction: {
                        send(.retryNextPage)
                    }
                )
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
            send(.viewDidAppear)
        }
    }
}

private extension IssuesView {
    func send(_ input: IssuesInput) {
        Task { await viewModel.trigger(input) }
    }

    struct Content: View {
        let content: IssuesViewState.Content
        let loadNextPageAction: () -> Void
        let retryNextPageAction: () -> Void

        var body: some View {
            if content.items.isEmpty {
                ContentUnavailableView {
                    Label(
                        .issuesEmptyTitle,
                        systemImage: AppIcons.table
                    )
                }
            } else {
                List {
                    ForEach(content.items) { item in
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
                        .onAppear {
                            guard item.id == content.items.last?.id else {
                                return
                            }
                            loadNextPageAction()
                        }
                    }

                    PaginationFooter(
                        status: content.paginationStatus,
                        retryTitle: .issuesPaginationRetry,
                        onRetry: retryNextPageAction
                    )
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
