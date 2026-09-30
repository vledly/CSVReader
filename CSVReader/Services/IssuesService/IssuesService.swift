import Foundation

final class IssuesService: Sendable {
    private let parser: any CSVParsing
    private let mapper = IssuesServiceMapper()
    private let pageSize: Int

    init(
        parser: any CSVParsing,
        pageSize: Int = 100
    ) {
        precondition(pageSize > 0)

        self.parser = parser
        self.pageSize = pageSize
    }

    func fetchPage(
        from fileURL: URL,
        offset: Int
    ) async throws -> IssuesPage {
        let page = try await parser.parse(
            fileURL: fileURL,
            offset: offset,
            limit: pageSize
        )
        return try mapper.map(page)
    }
}
