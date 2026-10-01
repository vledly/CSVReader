import SwiftUI
import UniformTypeIdentifiers

struct IssuesView<ViewModel: Store<IssuesViewState, IssuesInput>>: View {
    @State private var viewModel: ViewModel
    @State private var isFileImporterPresented = false

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label(
                        .issuesFilePickerButtonTitle,
                        systemImage: AppIcons.chooseFile
                    )
                }
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            guard case .success(let fileURL) = result else {
                return
            }
            send(.fileSelected(fileURL))
        }
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
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let content: IssuesViewState.Content
        let loadNextPageAction: () -> Void
        let retryNextPageAction: () -> Void

        private var usesTableLayout: Bool {
            horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
        }

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
                    if usesTableLayout {
                        tableHeader
                    }

                    ForEach(content.items) { item in
                        row(for: item)
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

        @ViewBuilder
        private func row(for item: IssuesViewState.Item) -> some View {
            if usesTableLayout {
                HStack {
                    Text(item.name)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.issueCountValue)
                        .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.dateOfBirth)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 4)
            } else {
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

        private var tableHeader: some View {
            HStack {
                Text(.issuesColumnName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(.issuesColumnIssueCount)
                    .frame(maxWidth: .infinity, alignment: .leading)

            Text(.issuesColumnDateOfBirth)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
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
