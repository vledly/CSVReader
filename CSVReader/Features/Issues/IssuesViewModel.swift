import Foundation
import Observation

@MainActor
@Observable
final class IssuesViewModel: Store {
    private struct Context {
        var fileURL: URL?
        var nextOffset = 0
        var loadTask: Task<Void, Never>?
    }

    private enum PageLoad {
        case first
        case next(expectedStatus: PaginationStatus)
    }

    private struct LoadedPage {
        let presentation: IssuesViewState.Presentation
        let itemCount: Int
        let hasMore: Bool
    }

    private(set) var state = IssuesViewState()
    private let dependencies: IssuesDependencies
    private let mapper: IssuesStateMapper
    @ObservationIgnored private var context: Context

    init(
        dependencies: IssuesDependencies,
        mapper: IssuesStateMapper = IssuesStateMapper()
    ) {
        self.dependencies = dependencies
        self.mapper = mapper
        context = Context(fileURL: dependencies.initialFileURL)
        if dependencies.initialFileURL == nil {
            state.status = .noFileSelected
        }
    }

    deinit {
        context.loadTask?.cancel()
    }

    func trigger(_ input: IssuesInput) async {
        switch input {
        case .viewDidFirstAppear:
            startLoading(.first)
        case .fileSelected(let fileURL):
            context.fileURL = fileURL
            startLoading(.first)
        case .presentationModeSelected(let mode):
            guard state.presentationMode != mode else { return }
            state.presentationMode = mode
            startLoading(.first)
        case .loadNextPage:
            startLoading(.next(expectedStatus: .ready))
        case .retryNextPage:
            startLoading(.next(expectedStatus: .failed))
        }
    }
}

private extension IssuesViewModel {
    private func startLoading(_ load: PageLoad) {
        guard let fileURL = context.fileURL else {
            state.status = .noFileSelected
            return
        }

        let currentPresentation: IssuesViewState.Presentation?
        switch load {
        case .first:
            cancelLoading()
            currentPresentation = nil
            context.nextOffset = 0
            state.status = .loading
        case .next(let expectedStatus):
            guard
                context.loadTask == nil,
                case .content(let content) = state.status,
                content.paginationStatus == expectedStatus
            else {
                return
            }
            currentPresentation = content.presentation
            state.status = .content(IssuesViewState.Content(
                presentation: content.presentation,
                paginationStatus: .loading
            ))
        }

        let offset = context.nextOffset
        let mode = state.presentationMode
        let csvService = dependencies.csvService
        let issuesService = dependencies.issuesService
        let mapper = mapper

        context.loadTask = Task { [weak self] in
            do {
                let loadedPage: LoadedPage
                switch mode {
                case .issues:
                    let page = try await issuesService.fetchPage(
                        from: fileURL,
                        offset: offset
                    )
                    loadedPage = LoadedPage(
                        presentation: .issues(mapper.map(
                            page.items,
                            offset: offset
                        )),
                        itemCount: page.items.count,
                        hasMore: page.hasMore
                    )
                case .table:
                    let page = try await csvService.fetchPage(
                        from: fileURL,
                        offset: offset
                    )
                    loadedPage = LoadedPage(
                        presentation: .table(mapper.map(page)),
                        itemCount: page.rows.count,
                        hasMore: page.hasMore
                    )
                }
                try Task.checkCancellation()
                self?.finishLoading(
                    loadedPage: loadedPage,
                    currentPresentation: currentPresentation,
                    offset: offset
                )
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.failLoading(
                    currentPresentation: currentPresentation,
                    load: load
                )
            }
        }
    }

    private func finishLoading(
        loadedPage: LoadedPage,
        currentPresentation: IssuesViewState.Presentation?,
        offset: Int
    ) {
        let presentation = append(
            loadedPage.presentation,
            to: currentPresentation
        )

        context.loadTask = nil
        context.nextOffset = offset + loadedPage.itemCount
        state.status = .content(
            IssuesViewState.Content(
                presentation: presentation,
                paginationStatus: loadedPage.hasMore ? .ready : .end
            )
        )
    }

    private func failLoading(
        currentPresentation: IssuesViewState.Presentation?,
        load: PageLoad
    ) {
        context.loadTask = nil
        switch load {
        case .first:
            state.status = .failure
        case .next:
            guard let currentPresentation else {
                state.status = .failure
                return
            }
            state.status = .content(IssuesViewState.Content(
                presentation: currentPresentation,
                paginationStatus: .failed
            ))
        }
    }

    func append(
        _ newPresentation: IssuesViewState.Presentation,
        to currentPresentation: IssuesViewState.Presentation?
    ) -> IssuesViewState.Presentation {
        guard let currentPresentation else {
            return newPresentation
        }

        switch (currentPresentation, newPresentation) {
        case (.issues(let currentItems), .issues(let newItems)):
            return .issues(currentItems + newItems)
        case (.table(let currentTable), .table(let newTable)):
            return .table(IssuesViewState.Table(
                headers: currentTable.headers,
                rows: currentTable.rows + newTable.rows
            ))
        default:
            return newPresentation
        }
    }

    func cancelLoading() {
        context.loadTask?.cancel()
        context.loadTask = nil
    }
}
