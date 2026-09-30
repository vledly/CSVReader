struct IssuesViewState {
    enum Status {
        case initial
        case ready
    }

    var status: Status = .initial
}
