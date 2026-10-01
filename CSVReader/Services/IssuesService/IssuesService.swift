import Foundation

final class IssuesService: Sendable {
    private let csvService: CSVService
    private let mapper = IssuesServiceMapper()

    init(csvService: CSVService) {
        self.csvService = csvService
    }

    func fetchPage(
        from fileURL: URL,
        offset: Int
    ) async throws -> IssuesPage {
        let page = try await csvService.fetchPage(
            from: fileURL,
            offset: offset
        )
        return try mapper.map(page)
    }
}
