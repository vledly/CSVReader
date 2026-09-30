import Foundation
import TabularData

actor TabularDataCSVParser: CSVParsing {
    func parse(
        fileURL: URL,
        offset: Int,
        limit: Int
    ) async throws -> CSVPageDTO {
        precondition(offset >= 0)
        precondition(limit > 0)

        let hasAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        try Task.checkCancellation()

        let options = CSVReadingOptions(
            hasHeaderRow: true,
            ignoresEmptyLines: true,
            usesQuoting: true,
            usesEscaping: false,
            delimiter: ","
        )
        let requestedRows = offset..<(offset + limit + 1)
        let frame = try DataFrame(
            contentsOfCSVFile: fileURL,
            rows: requestedRows,
            options: options
        )
        let headers = frame.columns.map(\.name)
        let hasMore = frame.rows.count > limit

        let rows = try frame.rows.prefix(limit).map { row in
            try Task.checkCancellation()
            return headers.map { header in
                guard let value = row[header] else { return "" }
                return String(describing: value)
            }
        }

        return CSVPageDTO(
            headers: headers,
            rows: rows,
            offset: offset,
            hasMore: hasMore
        )
    }
}
