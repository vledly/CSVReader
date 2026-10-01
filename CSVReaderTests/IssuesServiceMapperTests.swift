import Foundation
import Testing
@testable import CSVReader

@Suite("IssuesServiceMapper")
struct IssuesServiceMapperTests {
    private let mapper = IssuesServiceMapper()

    @Test("Maps a valid CSV page to issues")
    func mapsValidPage() throws {
        let page = makePage(
            rows: [[
                "Theo",
                "Jansen",
                "5",
                "1978-01-02T00:00:00"
            ]],
            hasMore: true
        )

        let result = try mapper.map(page)
        let issue = try #require(result.items.first)
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let dateComponents = Calendar(identifier: .gregorian).dateComponents(
            in: timeZone,
            from: issue.dateOfBirth
        )

        #expect(result.items.count == 1)
        #expect(result.hasMore == true)
        #expect(issue.firstName == "Theo")
        #expect(issue.surname == "Jansen")
        #expect(issue.issueCount == 5)
        #expect(dateComponents.year == 1978)
        #expect(dateComponents.month == 1)
        #expect(dateComponents.day == 2)
    }

    @Test("Maps values by header name when columns are reordered")
    func mapsReorderedColumns() throws {
        let page = makePage(
            headers: [
                "Issue count",
                "Date of birth",
                "Sur name",
                "First name"
            ],
            rows: [[
                "7",
                "1950-11-12T00:00:00",
                "de Vries",
                "Fiona"
            ]]
        )

        let result = try mapper.map(page)
        let issue = try #require(result.items.first)

        #expect(issue.firstName == "Fiona")
        #expect(issue.surname == "de Vries")
        #expect(issue.issueCount == 7)
    }

    @Test("Throws when a required column is missing")
    func throwsForMissingColumn() {
        let page = makePage(
            headers: [
                "First name",
                "Issue count",
                "Date of birth"
            ],
            rows: [[
                "Theo",
                "5",
                "1978-01-02T00:00:00"
            ]]
        )

        let error = #expect(throws: IssuesServiceMapperError.self) {
            try mapper.map(page)
        }
        let isExpectedError: Bool
        if case .missingColumn("Sur name")? = error {
            isExpectedError = true
        } else {
            isExpectedError = false
        }

        #expect(isExpectedError)
    }

    @Test("Throws when a required value is empty")
    func throwsForEmptyValue() {
        let page = makePage(
            rows: [[
                "",
                "Jansen",
                "5",
                "1978-01-02T00:00:00"
            ]]
        )

        let error = #expect(throws: IssuesServiceMapperError.self) {
            try mapper.map(page)
        }
        let isExpectedError: Bool
        if case .missingValue(column: "First name", row: 2)? = error {
            isExpectedError = true
        } else {
            isExpectedError = false
        }

        #expect(isExpectedError)
    }

    @Test("Throws for an invalid issue count and reports the CSV row")
    func throwsForInvalidIssueCount() {
        let page = makePage(
            rows: [[
                "Theo",
                "Jansen",
                "five",
                "1978-01-02T00:00:00"
            ]],
            offset: 10
        )

        let error = #expect(throws: IssuesServiceMapperError.self) {
            try mapper.map(page)
        }
        let isExpectedError: Bool
        if case .invalidIssueCount(value: "five", row: 12)? = error {
            isExpectedError = true
        } else {
            isExpectedError = false
        }

        #expect(isExpectedError)
    }

    @Test("Throws for an invalid date")
    func throwsForInvalidDate() {
        let page = makePage(
            rows: [[
                "Theo",
                "Jansen",
                "5",
                "not-a-date"
            ]]
        )

        let error = #expect(throws: IssuesServiceMapperError.self) {
            try mapper.map(page)
        }
        let isExpectedError: Bool
        if case .invalidDate(value: "not-a-date", row: 2)? = error {
            isExpectedError = true
        } else {
            isExpectedError = false
        }

        #expect(isExpectedError)
    }
}

private extension IssuesServiceMapperTests {
    func makePage(
        headers: [String] = [
            "First name",
            "Sur name",
            "Issue count",
            "Date of birth"
        ],
        rows: [[String]],
        offset: Int = 0,
        hasMore: Bool = false
    ) -> CSVPageDTO {
        CSVPageDTO(
            headers: headers,
            rows: rows,
            offset: offset,
            hasMore: hasMore
        )
    }
}
