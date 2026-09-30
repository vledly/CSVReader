import Foundation

protocol CSVParsing: Sendable {
    func parse(
        fileURL: URL,
        offset: Int,
        limit: Int
    ) async throws -> CSVPageDTO
}
