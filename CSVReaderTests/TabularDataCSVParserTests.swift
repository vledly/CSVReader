import Foundation
import Testing
@testable import CSVReader

@Suite("TabularDataCSVParser")
struct TabularDataCSVParserTests {
    @Test("Parses headers and rows")
    func parsesHeadersAndRows() async throws {
        try await withCSV(
            """
            "First name","Sur name","Issue count","Date of birth"
            "Theo","Jansen",5,"1978-01-02T00:00:00"
            "Fiona","de Vries",7,"1950-11-12T00:00:00"
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 0,
                limit: 100
            )

            #expect(page.headers == [
                "First name",
                "Sur name",
                "Issue count",
                "Date of birth"
            ])
            #expect(page.rows.count == 2)
            #expect(page.rows[0][0] == "Theo")
            #expect(page.rows[1][1] == "de Vries")
            #expect(page.hasMore == false)
        }
    }

    @Test(
        "Detects a supported delimiter",
        arguments: [Character(","), Character(";"), Character("\t")]
    )
    func detectsSupportedDelimiter(_ delimiter: Character) async throws {
        let firstHeader: String
        switch delimiter {
        case ",":
            firstHeader = "Display; name"
        case ";":
            firstHeader = "Display, name"
        default:
            firstHeader = "Display, name; label"
        }

        try await withCSV(
            """
            "\(firstHeader)"\(delimiter)"Value"
            "Smith, Jr."\(delimiter)"10"
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 0,
                limit: 100
            )

            #expect(page.headers == [firstHeader, "Value"])
            #expect(page.rows == [["Smith, Jr.", "10"]])
        }
    }

    @Test("Respects limit and detects the next page")
    func respectsLimitAndDetectsNextPage() async throws {
        try await withCSV(
            """
            "Name"
            "First"
            "Second"
            "Third"
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 0,
                limit: 2
            )

            #expect(page.rows == [["First"], ["Second"]])
            #expect(page.hasMore == true)
        }
    }

    @Test("Returns false when the page contains exactly the limit")
    func returnsFalseWhenPageContainsExactlyLimit() async throws {
        try await withCSV(
            """
            "Name"
            "First"
            "Second"
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 0,
                limit: 2
            )

            #expect(page.rows == [["First"], ["Second"]])
            #expect(page.hasMore == false)
        }
    }

    @Test("Uses offset and detects the last page")
    func usesOffsetAndDetectsLastPage() async throws {
        try await withCSV(
            """
            "Name"
            "First"
            "Second"
            "Third"
            "Fourth"
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 2,
                limit: 2
            )

            #expect(page.rows == [["Third"], ["Fourth"]])
            #expect(page.offset == 2)
            #expect(page.hasMore == false)
        }
    }

    @Test("Keeps a comma inside a quoted value")
    func handlesCommaInsideQuotes() async throws {
        try await withCSV(
            """
            "First name","Sur name"
            "John","Smith, Jr."
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 0,
                limit: 100
            )
            let row = try #require(page.rows.first)

            #expect(row == ["John", "Smith, Jr."])
        }
    }

    @Test("Ignores empty lines")
    func ignoresEmptyLines() async throws {
        try await withCSV(
            """
            "Name"
            "First"

            "Second"
            """
        ) { fileURL in
            let page = try await TabularDataCSVParser().parse(
                fileURL: fileURL,
                offset: 0,
                limit: 100
            )

            #expect(page.rows == [["First"], ["Second"]])
        }
    }

}

private extension TabularDataCSVParserTests {
    func withCSV<Result>(
        _ contents: String,
        operation: (URL) async throws -> Result
    ) async throws -> Result {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("csv")

        try Data(contents.utf8).write(
            to: fileURL,
            options: .atomic
        )
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        return try await operation(fileURL)
    }
}
