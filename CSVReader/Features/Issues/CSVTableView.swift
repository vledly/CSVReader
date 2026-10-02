import SwiftUI

struct CSVTableView: View {
    let table: IssuesViewState.Table
    let paginationStatus: PaginationStatus
    let loadNextPageAction: () -> Void
    let retryNextPageAction: () -> Void

    var body: some View {
        if table.rows.isEmpty {
            ContentUnavailableView {
                Label(
                    .issuesTableEmptyTitle,
                    systemImage: AppIcons.table
                )
            }
        } else {
            GeometryReader { geometry in
                let columnCount = max(table.headers.count, 1)
                let columnWidth = max(
                    geometry.size.width / CGFloat(columnCount),
                    160
                )
                let tableWidth = columnWidth * CGFloat(columnCount)

                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(
                        alignment: .leading,
                        spacing: 0,
                        pinnedViews: [.sectionHeaders]
                    ) {
                        Section {
                            ForEach(table.rows) { row in
                                TableRow(
                                    row: row,
                                    columnCount: columnCount,
                                    columnWidth: columnWidth
                                )
                                .onAppear {
                                    guard row.id == table.rows.last?.id else {
                                        return
                                    }
                                    loadNextPageAction()
                                }

                                Divider()
                            }
                        } header: {
                            TableHeader(
                                headers: table.headers,
                                columnWidth: columnWidth
                            )
                            .background(.background)
                        }

                        PaginationFooter(
                            status: paginationStatus,
                            retryTitle: .issuesPaginationRetry,
                            onRetry: retryNextPageAction
                        )
                        .frame(width: tableWidth)
                        .padding(.vertical, 8)
                    }
                    .frame(
                        width: max(tableWidth, geometry.size.width),
                        alignment: .leading
                    )
                }
            }
        }
    }
}

private extension CSVTableView {
    struct TableHeader: View {
        let headers: [String]
        let columnWidth: CGFloat

        var body: some View {
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: columnWidth, alignment: .leading)
                }
            }
        }
    }

    struct TableRow: View {
        let row: IssuesViewState.TableRow
        let columnCount: Int
        let columnWidth: CGFloat

        var body: some View {
            HStack(spacing: 0) {
                ForEach(0..<columnCount, id: \.self) { index in
                    Text(row.values.indices.contains(index) ? row.values[index] : "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: columnWidth, alignment: .leading)
                }
            }
        }
    }
}
