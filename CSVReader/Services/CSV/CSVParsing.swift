import Foundation

protocol CSVParsing: Sendable {
    func parse(fileURL: URL) async throws -> CSVDocumentDTO
}
