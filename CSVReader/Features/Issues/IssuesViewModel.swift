import Observation

@MainActor
@Observable
final class IssuesViewModel: Store {
    private(set) var state = IssuesViewState()

    func trigger(_ input: IssuesInput) async {
        switch input {
        case .viewDidAppear:
            state.status = .ready
        }
    }
}
