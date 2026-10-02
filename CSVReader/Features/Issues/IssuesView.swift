import SwiftUI
import UniformTypeIdentifiers

struct IssuesView<ViewModel: Store<IssuesViewState, IssuesInput>>: View {
    @State private var viewModel: ViewModel
    @State private var isFileImporterPresented = false

    init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(
                .issuesPresentationTitle,
                selection: presentationMode
            ) {
                ForEach(IssuesViewState.PresentationMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch viewModel.state.status {
                case .initial, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .noFileSelected:
                    ContentUnavailableView {
                        Label(
                            .issuesEmptyNoSelectionTitle,
                            systemImage: AppIcons.chooseFile
                        )
                    } actions: {
                        Button(.issuesFilePickerButtonTitle) {
                            isFileImporterPresented = true
                        }
                    }
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
        .onFirstAppear {
            send(.viewDidFirstAppear)
        }
    }
}

private extension IssuesView {
    var presentationMode: Binding<IssuesViewState.PresentationMode> {
        Binding(
            get: { viewModel.state.presentationMode },
            set: { send(.presentationModeSelected($0)) }
        )
    }

    func send(_ input: IssuesInput) {
        Task { await viewModel.trigger(input) }
    }

    struct Content: View {
        let content: IssuesViewState.Content
        let loadNextPageAction: () -> Void
        let retryNextPageAction: () -> Void

        var body: some View {
            switch content.presentation {
            case .issues(let items):
                IssuesListView(
                    items: items,
                    paginationStatus: content.paginationStatus,
                    loadNextPageAction: loadNextPageAction,
                    retryNextPageAction: retryNextPageAction
                )
            case .table(let table):
                CSVTableView(
                    table: table,
                    paginationStatus: content.paginationStatus,
                    loadNextPageAction: loadNextPageAction,
                    retryNextPageAction: retryNextPageAction
                )
            }
        }
    }
}

private extension IssuesViewState.PresentationMode {
    var title: LocalizedStringResource {
        switch self {
        case .issues:
            .issuesPresentationIssues
        case .table:
            .issuesPresentationTable
        }
    }
}

#Preview {
    let csvService = CSVService(parser: TabularDataCSVParser())

    NavigationStack {
        IssuesAssembly.makeView(
            dependencies: IssuesDependencies(
                csvService: csvService,
                issuesService: IssuesService(csvService: csvService),
                initialFileURL: Bundle.main.url(
                    forResource: "issues",
                    withExtension: "csv"
                )
            )
        )
    }
}
