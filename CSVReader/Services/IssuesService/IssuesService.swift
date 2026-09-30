import Foundation

final class IssuesService: Sendable {
    private let parser: any CSVParsing
    private let mapper = IssuesServiceMapper()

    init(parser: any CSVParsing) {
        self.parser = parser
    }

    func fetch(from fileURL: URL) async throws -> [Issue] {
        let document = try await parser.parse(fileURL: fileURL)
        return try mapper.map(document)
    }
}
