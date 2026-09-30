import Foundation

@MainActor
final class AppContainer {
    let csvParser: any CSVParsing
    let issuesService: IssuesService
    let issuesDependencies: IssuesDependencies

    init(
        csvParser: any CSVParsing = TabularDataCSVParser(),
        bundle: Bundle = .main
    ) {
        let issuesService = IssuesService(parser: csvParser)

        self.csvParser = csvParser
        self.issuesService = issuesService
        issuesDependencies = IssuesDependencies(
            issuesService: issuesService,
            initialFileURL: bundle.url(
                forResource: "issues-large",
                withExtension: "csv"
            )
        )
    }
}
