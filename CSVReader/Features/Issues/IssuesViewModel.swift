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
    }

    deinit {
        context.loadTask?.cancel()
    }

    func trigger(_ input: IssuesInput) async {
        switch input {
        case .viewDidAppear:
            guard case .initial = state.status else { return }
            startLoading(.first)
        case .fileSelected(let fileURL):
            context.fileURL = fileURL
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
        let currentItems: [IssuesViewState.Item]
        switch load {
        case .first:
            cancelLoading()
            currentItems = []
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
            currentItems = content.items
            state.status = .content(IssuesViewState.Content(
                items: currentItems,
                paginationStatus: .loading
            ))
        }

        guard let fileURL = context.fileURL else {
            state.status = .failure
            return
        }

        let offset = context.nextOffset
        let issuesService = dependencies.issuesService
        let mapper = mapper

        context.loadTask = Task { [weak self] in
            do {
                let page = try await issuesService.fetchPage(
                    from: fileURL,
                    offset: offset
                )
                try Task.checkCancellation()
                let newItems = mapper.map(
                    page.items,
                    offset: offset
                )
                self?.finishLoading(
                    page: page,
                    newItems: newItems,
                    currentItems: currentItems,
                    load: load,
                    offset: offset
                )
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.failLoading(
                    currentItems: currentItems,
                    load: load
                )
            }
        }
    }

    private func finishLoading(
        page: IssuesPage,
        newItems: [IssuesViewState.Item],
        currentItems: [IssuesViewState.Item],
        load: PageLoad,
        offset: Int
    ) {
        let items: [IssuesViewState.Item]
        switch load {
        case .first:
            items = newItems
        case .next:
            items = currentItems + newItems
        }

        context.loadTask = nil
        context.nextOffset = offset + page.items.count
        state.status = .content(
            IssuesViewState.Content(
                items: items,
                paginationStatus: page.hasMore ? .ready : .end
            )
        )
    }

    private func failLoading(
        currentItems: [IssuesViewState.Item],
        load: PageLoad
    ) {
        context.loadTask = nil
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

    func cancelLoading() {
        context.loadTask?.cancel()
        context.loadTask = nil
    }
}
