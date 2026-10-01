import Foundation

struct IssuesStateMapper {
    func map(
        _ issues: [Issue],
        offset: Int
    ) -> [IssuesViewState.Item] {
        issues.enumerated().map { index, issue in
            IssuesViewState.Item(
                id: offset + index,
                name: "\(issue.firstName) \(issue.surname)",
                issueCount: String(
                    localized: .issuesRowIssueCount(issue.issueCount)
                ),
                issueCountValue: String(issue.issueCount),
                dateOfBirth: issue.dateOfBirth.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )
        }
    }

    func map(_ page: CSVPageDTO) -> IssuesViewState.Table {
        let rows = page.rows.enumerated().map { index, values in
            IssuesViewState.TableRow(
                id: page.offset + index,
                values: page.headers.indices.map { columnIndex in
                    guard values.indices.contains(columnIndex) else {
                        return ""
                    }

                    return values[columnIndex]
                }
            )
        }

        return IssuesViewState.Table(
            headers: page.headers,
            rows: rows
        )
    }
}
