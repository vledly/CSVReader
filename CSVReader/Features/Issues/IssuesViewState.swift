struct IssuesViewState: Sendable {
    enum Status: Sendable {
        case initial
        case loading
        case content(Content)
        case failure
    }

    struct Content: Sendable {
        let items: [Item]
        let paginationStatus: PaginationStatus
    }

    struct Item: Identifiable, Sendable {
        let id: Int
        let name: String
        let issueCount: String
        let issueCountValue: String
        let dateOfBirth: String
    }

    var status: Status = .initial
}
