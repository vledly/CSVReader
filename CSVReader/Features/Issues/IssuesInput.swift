import Foundation

enum IssuesInput: Sendable {
    case viewDidFirstAppear
    case fileSelected(URL)
    case presentationModeSelected(IssuesViewState.PresentationMode)
    case loadNextPage
    case retryNextPage
}
