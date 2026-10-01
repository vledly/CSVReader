import Foundation

enum IssuesInput: Sendable {
    case viewDidAppear
    case fileSelected(URL)
    case presentationModeSelected(IssuesViewState.PresentationMode)
    case loadNextPage
    case retryNextPage
}
