import SwiftUI

struct QueueSettingsView: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var isImporting: Bool

    var body: some View {
        DroplitSettingsPage(
            title: DroplitSettingsSection.queue.title,
            subtitle: "Review recent optimization jobs, open outputs, and remove finished or pending items."
        ) {
            DroplitSettingsGroup(
                "Overview",
                description: "Import more files or review the current optimization state."
            ) {
                DroplitSettingsControlRow(
                    title: "Optimization Status",
                    subtitle: queueSummaryText
                ) {
                    Button("Optimize...") {
                        isImporting = true
                    }
                }
            }

            if quickAccess.items.isEmpty {
                DroplitEmptyStateView(
                    title: "No Jobs Yet",
                    systemImage: "tray",
                    description: "Use Quick Access or import files to start optimizing."
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                DroplitSettingsGroup(
                    "Jobs",
                    description: "Recent imports and Quick Access optimizations."
                ) {
                    ForEach(Array(quickAccess.items.enumerated()), id: \.element.id) { index, item in
                        QueueSettingsRow(item: item, quickAccess: quickAccess)
                        if index < quickAccess.items.count - 1 {
                            DroplitSettingsDivider()
                        }
                    }
                }
            }
        }
    }

    private var queueSummaryText: String {
        let total = quickAccess.items.count
        guard total > 0 else { return "No active jobs" }
        return "\(quickAccess.processingCount) running, \(quickAccess.stagedCount) ready, \(quickAccess.queuedCount) queued, \(total) total"
    }
}

private struct QueueSettingsRow: View {
    let item: QuickAccessItem
    @ObservedObject var quickAccess: QuickAccessManager

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: item.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.sourceURL.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)
                Text(item.detailLine)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            statusBadge

            Button {
                quickAccess.removeItem(id: item.id)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            .help("Remove")
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.state {
        case .staged:
            Text("Ready")
                .font(.callout.weight(.medium))
                .foregroundColor(.secondary)
        case .queued:
            Text("Queued")
                .font(.callout.weight(.medium))
                .foregroundColor(.secondary)
        case .processing:
            ProgressView()
                .controlSize(.small)
        case .completed:
            Text("Done")
                .font(.callout.weight(.medium))
                .foregroundColor(.green)
        case .failed:
            Text("Failed")
                .font(.callout.weight(.medium))
                .foregroundColor(.orange)
        }
    }
}
