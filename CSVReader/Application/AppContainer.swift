@MainActor
final class AppContainer {
    let csvParser: any CSVParsing

    init(csvParser: any CSVParsing = TabularDataCSVParser()) {
        self.csvParser = csvParser
    }
}
