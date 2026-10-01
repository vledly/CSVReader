import Foundation

final class CSVService: Sendable {
    private let parser: any CSVParsing
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
    ) async throws -> CSVPageDTO {
        try await parser.parse(
            fileURL: fileURL,
            offset: offset,
            limit: pageSize
        )
    }
}
