import Foundation

struct IssuesDependencies: Sendable {
    let issuesService: IssuesService
    let initialFileURL: URL?
}
