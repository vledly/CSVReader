struct CSVPageDTO: Sendable {
    let headers: [String]
    let rows: [[String]]
    let offset: Int
    let hasMore: Bool
}
