import Foundation
import Observation

@MainActor
@Observable
final class IssuesViewModel: Store {
    private struct Context {
        var fileURL: URL?
        var nextOffset = 0
        var activeLoadID: UUID?
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

    func trigger(_ input: IssuesInput) async {
        switch input {
        case .viewDidAppear:
            guard case .initial = state.status else { return }
            await loadPage(.first)
        case .fileSelected(let fileURL):
            context.fileURL = fileURL
            context.activeLoadID = nil
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
        let currentItems: [IssuesViewState.Item]
        switch load {
        case .first:
            currentItems = []
            context.nextOffset = 0
            state.status = .loading
        case .next(let expectedStatus):
            guard
                context.activeLoadID == nil,
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

        let loadID = UUID()
        context.activeLoadID = loadID
        defer {
            if context.activeLoadID == loadID {
                context.activeLoadID = nil
            }
        }

        do {
            let page = try await dependencies.issuesService.fetchPage(
                from: fileURL,
                offset: context.nextOffset
            )
            guard context.activeLoadID == loadID else {
                return
            }
            try Task.checkCancellation()
            let newItems = mapper.map(
                page.items,
                offset: context.nextOffset
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
            context.nextOffset += page.items.count
        } catch is CancellationError {
            return
        } catch {
            guard context.activeLoadID == loadID else {
                return
            }
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
