import Foundation

enum IssuesInput: Sendable {
    case viewDidAppear
    case fileSelected(URL)
    case loadNextPage
    case retryNextPage
}
