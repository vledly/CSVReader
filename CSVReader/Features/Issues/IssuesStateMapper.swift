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
}
