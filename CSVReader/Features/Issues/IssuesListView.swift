import SwiftUI

struct IssuesListView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let items: [IssuesViewState.Item]
    let paginationStatus: PaginationStatus
    let loadNextPageAction: () -> Void
    let retryNextPageAction: () -> Void

    private var usesTableLayout: Bool {
        horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label(
                    .issuesEmptyTitle,
                    systemImage: AppIcons.table
                )
            }
        } else {
            List {
                if usesTableLayout {
                    TableHeader()
                }

                ForEach(items) { item in
                    Row(item: item, usesTableLayout: usesTableLayout)
                        .onAppear {
                            guard item.id == items.last?.id else {
                                return
                            }
                            loadNextPageAction()
                        }
                }

                PaginationFooter(
                    status: paginationStatus,
                    retryTitle: .issuesPaginationRetry,
                    onRetry: retryNextPageAction
                )
            }
        }
    }
}

private extension IssuesListView {
    struct Row: View {
        let item: IssuesViewState.Item
        let usesTableLayout: Bool

        @ViewBuilder
        var body: some View {
            if usesTableLayout {
                HStack {
                    Text(item.name)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.issueCountValue)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(item.dateOfBirth)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)

                    HStack {
                        Text(item.issueCount)
                        Spacer()
                        Text(item.dateOfBirth)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    struct TableHeader: View {
        var body: some View {
            HStack {
                Text(.issuesColumnName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(.issuesColumnIssueCount)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(.issuesColumnDateOfBirth)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
        }
    }
}
