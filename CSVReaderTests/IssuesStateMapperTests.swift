import Testing
@testable import CSVReader

@Suite("IssuesStateMapper")
struct IssuesStateMapperTests {
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
