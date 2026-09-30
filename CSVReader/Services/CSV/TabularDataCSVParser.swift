import Foundation
import TabularData

actor TabularDataCSVParser: CSVParsing {
    func parse(fileURL: URL) async throws -> CSVDocumentDTO {
        let hasAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: fileURL)
        try Task.checkCancellation()

        guard !data.isEmpty else {
            return CSVDocumentDTO(headers: [], rows: [])
        }

        let options = CSVReadingOptions(
            hasHeaderRow: true,
            ignoresEmptyLines: true,
            usesQuoting: true,
            usesEscaping: false,
            delimiter: ","
        )
        let frame = try DataFrame(csvData: data, options: options)
        let headers = frame.columns.map(\.name)

        let rows = try frame.rows.map { row in
            try Task.checkCancellation()
            return headers.map { header in
                guard let value = row[header] else { return "" }
                return String(describing: value)
            }
        }

        return CSVDocumentDTO(headers: headers, rows: rows)
    }
}
