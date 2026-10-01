import Foundation
import TabularData

actor TabularDataCSVParser: CSVParsing {
    private static let supportedDelimiters: [UInt8] = [
        UInt8(ascii: ","),
        UInt8(ascii: ";"),
        UInt8(ascii: "\t")
    ]

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

        let delimiter = try detectDelimiter(in: fileURL)
        let options = CSVReadingOptions(
            hasHeaderRow: true,
            ignoresEmptyLines: true,
            usesQuoting: true,
            usesEscaping: false,
            delimiter: delimiter
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

private extension TabularDataCSVParser {
    func detectDelimiter(in fileURL: URL) throws -> Character {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var counts = Dictionary(
            uniqueKeysWithValues: Self.supportedDelimiters.map { ($0, 0) }
        )
        var isInsideQuotes = false
        var reachedEndOfHeader = false

        while !reachedEndOfHeader {
            try Task.checkCancellation()

            guard
                let data = try fileHandle.read(upToCount: 4_096),
                !data.isEmpty
            else {
                break
            }

            for byte in data {
                if byte == UInt8(ascii: "\"") {
                    isInsideQuotes.toggle()
                } else if !isInsideQuotes && (byte == 10 || byte == 13) {
                    reachedEndOfHeader = true
                    break
                } else if !isInsideQuotes && counts[byte] != nil {
                    counts[byte, default: 0] += 1
                }
            }
        }

        let delimiter = Self.supportedDelimiters.reduce(
            Self.supportedDelimiters[0]
        ) { current, candidate in
            counts[candidate, default: 0] > counts[current, default: 0]
                ? candidate
                : current
        }

        return Character(UnicodeScalar(delimiter))
    }
}
