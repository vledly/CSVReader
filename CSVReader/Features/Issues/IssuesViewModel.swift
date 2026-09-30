import Observation

@MainActor
@Observable
final class IssuesViewModel: Store {
    private(set) var state = IssuesViewState()
    private let dependencies: IssuesDependencies
    private let mapper: IssuesStateMapper

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
            await loadInitialFile()
        }
    }
}

private extension IssuesViewModel {
    func loadInitialFile() async {
        guard let fileURL = dependencies.initialFileURL else {
            state.status = .failure
            return
        }

        state.status = .loading

        do {
            let issues = try await dependencies.issuesService.fetch(from: fileURL)
            try Task.checkCancellation()
            state.status = .content(mapper.map(issues))
        } catch is CancellationError {
            return
        } catch {
            state.status = .failure
        }
    }
}
