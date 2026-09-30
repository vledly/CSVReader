import Foundation

enum IssuesServiceMapperError: Error {
    case missingColumn(String)
    case missingValue(column: String, row: Int)
    case invalidIssueCount(value: String, row: Int)
    case invalidDate(value: String, row: Int)
}

struct IssuesServiceMapper: Sendable {
    private enum Column {
        static let firstName = "First name"
        static let surname = "Sur name"
        static let issueCount = "Issue count"
        static let dateOfBirth = "Date of birth"
    }

    func map(_ document: CSVDocumentDTO) throws -> [Issue] {
        let firstNameIndex = try columnIndex(Column.firstName, in: document.headers)
        let surnameIndex = try columnIndex(Column.surname, in: document.headers)
        let issueCountIndex = try columnIndex(Column.issueCount, in: document.headers)
        let dateOfBirthIndex = try columnIndex(Column.dateOfBirth, in: document.headers)
        let dateFormatter = AppDateFormatters.csvDate()

        return try document.rows.enumerated().map { index, row in
            let csvRow = index + 2
            let firstName = try value(
                at: firstNameIndex,
                column: Column.firstName,
                row: row,
                csvRow: csvRow
            )
            let surname = try value(
                at: surnameIndex,
                column: Column.surname,
                row: row,
                csvRow: csvRow
            )
            let issueCountValue = try value(
                at: issueCountIndex,
                column: Column.issueCount,
                row: row,
                csvRow: csvRow
            )
            let dateOfBirthValue = try value(
                at: dateOfBirthIndex,
                column: Column.dateOfBirth,
                row: row,
                csvRow: csvRow
            )

            guard let issueCount = Int(issueCountValue) else {
                throw IssuesServiceMapperError.invalidIssueCount(
                    value: issueCountValue,
                    row: csvRow
                )
            }
            guard let dateOfBirth = dateFormatter.date(from: dateOfBirthValue) else {
                throw IssuesServiceMapperError.invalidDate(
                    value: dateOfBirthValue,
                    row: csvRow
                )
            }

            return Issue(
                firstName: firstName,
                surname: surname,
                issueCount: issueCount,
                dateOfBirth: dateOfBirth
            )
        }
    }
}

private extension IssuesServiceMapper {
    func columnIndex(_ column: String, in headers: [String]) throws -> Int {
        guard let index = headers.firstIndex(of: column) else {
            throw IssuesServiceMapperError.missingColumn(column)
        }

        return index
    }

    func value(
        at index: Int,
        column: String,
        row: [String],
        csvRow: Int
    ) throws -> String {
        guard row.indices.contains(index), !row[index].isEmpty else {
            throw IssuesServiceMapperError.missingValue(
                column: column,
                row: csvRow
            )
        }

        return row[index]
    }
}
