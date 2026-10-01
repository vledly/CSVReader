struct IssuesViewState: Sendable {
    enum PresentationMode: CaseIterable, Identifiable, Sendable {
        case issues
        case table

        var id: Self { self }
    }

    enum Status: Sendable {
        case initial
        case loading
        case content(Content)
        case failure
    }

    struct Content: Sendable {
        let presentation: Presentation
        let paginationStatus: PaginationStatus
    }

    enum Presentation: Sendable {
        case issues([Item])
        case table(Table)
    }

    struct Item: Identifiable, Sendable {
        let id: Int
        let name: String
        let issueCount: String
        let issueCountValue: String
        let dateOfBirth: String
    }

    struct Table: Sendable {
        let headers: [String]
        let rows: [TableRow]
    }

    struct TableRow: Identifiable, Sendable {
        let id: Int
        let values: [String]
    }

    var presentationMode: PresentationMode = .issues
    var status: Status = .initial
}
