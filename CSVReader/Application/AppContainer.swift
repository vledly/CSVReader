import Foundation

@MainActor
final class AppContainer {
    // true: open the bundled CSV; false: wait for a file chosen by URL.
    private static let loadsBundledCSVOnLaunch = true

    let csvParser: any CSVParsing
    let csvService: CSVService
    let issuesService: IssuesService
    let issuesDependencies: IssuesDependencies

    init(
        csvParser: any CSVParsing = TabularDataCSVParser(),
        bundle: Bundle = .main
    ) {
        let csvService = CSVService(parser: csvParser)
        let issuesService = IssuesService(csvService: csvService)

        self.csvParser = csvParser
        self.csvService = csvService
        self.issuesService = issuesService
        issuesDependencies = IssuesDependencies(
            csvService: csvService,
            issuesService: issuesService,
            initialFileURL: Self.loadsBundledCSVOnLaunch ? bundle.url(
                forResource: "issues",
                withExtension: "csv"
            ) : nil
        )
    }
}
