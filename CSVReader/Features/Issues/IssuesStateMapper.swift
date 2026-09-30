import Foundation

struct IssuesStateMapper {
    func map(_ issues: [Issue]) -> IssuesViewState.Content {
        let items = issues.enumerated().map { index, issue in
            IssuesViewState.Item(
                id: index,
                name: "\(issue.firstName) \(issue.surname)",
                issueCount: String(
                    localized: .issuesRowIssueCount(issue.issueCount)
                ),
                dateOfBirth: issue.dateOfBirth.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )
        }

        return IssuesViewState.Content(items: items)
    }
}
