struct IssuesViewState {
    enum Status {
        case initial
        case loading
        case content(Content)
        case failure
    }

    struct Content {
        let items: [Item]
    }

    struct Item: Identifiable {
        let id: Int
        let name: String
        let issueCount: String
        let dateOfBirth: String
    }

    var status: Status = .initial
}
