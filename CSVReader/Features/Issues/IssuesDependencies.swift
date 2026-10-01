import Foundation

struct IssuesDependencies: Sendable {
    let csvService: CSVService
    let issuesService: IssuesService
    let initialFileURL: URL?
}
