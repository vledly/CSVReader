import SwiftUI

struct PaginationFooter: View {
    let status: PaginationStatus
    let retryTitle: LocalizedStringResource
    let onRetry: () -> Void

    @ViewBuilder
    var body: some View {
        switch status {
        case .ready, .end:
            EmptyView()
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .failed:
            Button(retryTitle, action: onRetry)
                .frame(maxWidth: .infinity)
        }
    }
}
