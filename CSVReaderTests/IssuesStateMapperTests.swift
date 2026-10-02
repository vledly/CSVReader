import Foundation
import Testing
@testable import CSVReader

@Suite("IssuesStateMapper")
struct IssuesStateMapperTests {
    @Test("Keeps the birthday when the device is west of UTC")
    func keepsBirthdayInWesternTimeZone() throws {
        let birthDate = try #require(
            AppDateFormatters.csvDate().date(from: "1978-01-02T00:00:00")
        )
        let issue = Issue(
            firstName: "Theo",
            surname: "Jansen",
            issueCount: 5,
            dateOfBirth: birthDate
        )
        let item = try #require(
            IssuesStateMapper().map([issue], offset: 0).first
        )
        let expected = birthDate.formatted(Date.FormatStyle(
            date: .abbreviated,
            time: .omitted,
            timeZone: .gmt
        ))

        #expect(item.dateOfBirth == expected)
    }

    @Test("Maps an arbitrary CSV page to table state")
    func mapsArbitraryCSVPage() {
        let page = CSVPageDTO(
            headers: ["City", "Country", "Population"],
            rows: [
                ["Amsterdam", "Netherlands", "933680"],
                ["Utrecht", "Netherlands"]
            ],
            offset: 100,
            hasMore: true
        )

        let table = IssuesStateMapper().map(page)

        #expect(table.headers == ["City", "Country", "Population"])
        #expect(table.rows.count == 2)
        #expect(table.rows[0].id == 100)
        #expect(table.rows[0].values == [
            "Amsterdam",
            "Netherlands",
            "933680"
        ])
        #expect(table.rows[1].id == 101)
        #expect(table.rows[1].values == [
            "Utrecht",
            "Netherlands",
            ""
        ])
    }
}
