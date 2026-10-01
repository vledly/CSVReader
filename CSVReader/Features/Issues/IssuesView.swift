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
        .task {
            send(.viewDidAppear)
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
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let content: IssuesViewState.Content
        let loadNextPageAction: () -> Void
        let retryNextPageAction: () -> Void

        private var usesTableLayout: Bool {
            horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
        }

        var body: some View {
            switch content.presentation {
            case .issues(let items):
                issuesList(items)
            case .table(let table):
                csvTable(table)
            }
        }

        @ViewBuilder
        private func issuesList(_ items: [IssuesViewState.Item]) -> some View {
            if items.isEmpty {
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

                    ForEach(items) { item in
                        row(for: item)
                        .onAppear {
                            guard item.id == items.last?.id else {
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
        private func csvTable(_ table: IssuesViewState.Table) -> some View {
            if table.rows.isEmpty {
                ContentUnavailableView {
                    Label(
                        .issuesTableEmptyTitle,
                        systemImage: AppIcons.table
                    )
                }
            } else {
                GeometryReader { geometry in
                    let columnCount = max(table.headers.count, 1)
                    let columnWidth = max(
                        geometry.size.width / CGFloat(columnCount),
                        160
                    )
                    let tableWidth = columnWidth * CGFloat(columnCount)

                    ScrollView([.horizontal, .vertical]) {
                        LazyVStack(
                            alignment: .leading,
                            spacing: 0,
                            pinnedViews: [.sectionHeaders]
                        ) {
                            Section {
                                ForEach(table.rows) { row in
                                    tableRow(
                                        row,
                                        columnCount: columnCount,
                                        columnWidth: columnWidth
                                    )
                                    .onAppear {
                                        guard row.id == table.rows.last?.id else {
                                            return
                                        }
                                        loadNextPageAction()
                                    }

                                    Divider()
                                }
                            } header: {
                                tableHeader(
                                    table.headers,
                                    columnWidth: columnWidth
                                )
                                .background(.background)
                            }

                            PaginationFooter(
                                status: content.paginationStatus,
                                retryTitle: .issuesPaginationRetry,
                                onRetry: retryNextPageAction
                            )
                            .frame(width: tableWidth)
                            .padding(.vertical, 8)
                        }
                        .frame(
                            width: max(tableWidth, geometry.size.width),
                            alignment: .leading
                        )
                    }
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

        private func tableHeader(
            _ headers: [String],
            columnWidth: CGFloat
        ) -> some View {
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: columnWidth, alignment: .leading)
                }
            }
        }

        private func tableRow(
            _ row: IssuesViewState.TableRow,
            columnCount: Int,
            columnWidth: CGFloat
        ) -> some View {
            HStack(spacing: 0) {
                ForEach(0..<columnCount, id: \.self) { index in
                    Text(row.values.indices.contains(index) ? row.values[index] : "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: columnWidth, alignment: .leading)
                }
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
