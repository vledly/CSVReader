struct CSVDocumentDTO: Sendable {
    let headers: [String]
    let rows: [[String]]
}
