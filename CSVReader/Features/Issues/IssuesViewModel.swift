import Observation

@MainActor
@Observable
final class IssuesViewModel: Store {
    private enum PageLoad {
        case first
        case next(expectedStatus: PaginationStatus)
    }

    private(set) var state = IssuesViewState()
    private let dependencies: IssuesDependencies
    private let mapper: IssuesStateMapper
    @ObservationIgnored private var nextOffset = 0
    @ObservationIgnored private var isLoadingPage = false

    init(
        dependencies: IssuesDependencies,
        mapper: IssuesStateMapper = IssuesStateMapper()
    ) {
        self.dependencies = dependencies
        self.mapper = mapper
    }

    func trigger(_ input: IssuesInput) async {
        switch input {
        case .viewDidAppear:
            guard case .initial = state.status else { return }
            await loadPage(.first)
        case .loadNextPage:
            await loadPage(.next(expectedStatus: .ready))
        case .retryNextPage:
            await loadPage(.next(expectedStatus: .failed))
        }
    }
}

private extension IssuesViewModel {
    private func loadPage(_ load: PageLoad) async {
        guard !isLoadingPage else {
            return
        }

        let currentItems: [IssuesViewState.Item]
        switch load {
        case .first:
            currentItems = []
            nextOffset = 0
            state.status = .loading
        case .next(let expectedStatus):
            guard
                case .content(let content) = state.status,
                content.paginationStatus == expectedStatus
            else {
                return
            }
            currentItems = content.items
            state.status = .content(IssuesViewState.Content(
                items: currentItems,
                paginationStatus: .loading
            ))
        }

        guard let fileURL = dependencies.initialFileURL else {
            state.status = .failure
            return
        }

        isLoadingPage = true
        defer { isLoadingPage = false }

        do {
            let page = try await dependencies.issuesService.fetchPage(
                from: fileURL,
                offset: nextOffset
            )
            try Task.checkCancellation()
            let newItems = mapper.map(
                page.items,
                offset: nextOffset
            )
            let items: [IssuesViewState.Item]
            switch load {
            case .first:
                items = newItems
            case .next:
                items = currentItems + newItems
            }
            state.status = .content(
                IssuesViewState.Content(
                    items: items,
                    paginationStatus: page.hasMore ? .ready : .end
                )
            )
            nextOffset += page.items.count
        } catch is CancellationError {
            return
        } catch {
            switch load {
            case .first:
                state.status = .failure
            case .next:
                state.status = .content(IssuesViewState.Content(
                    items: currentItems,
                    paginationStatus: .failed
                ))
            }
        }
    }
}
