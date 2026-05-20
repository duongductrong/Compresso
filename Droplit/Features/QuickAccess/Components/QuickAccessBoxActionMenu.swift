import SwiftUI

struct QuickAccessBoxActionMenu: View {
    let items: [QuickAccessItem]
    let actions: QuickAccessPresentationActions

    var body: some View {
        if items.isEmpty {
            Button("Close") {
                actions.removeAllItems()
            }
        } else {
            Button(statusTitle) {}
                .disabled(true)

            if stagedCount > 0 {
                Divider()

                Button(optimizeTitle) {
                    actions.processAllStagedItems()
                }
            }

            if let latestItem {
                Divider()

                Button(latestItem.outputURL == nil ? "Open Latest Original" : "Open Latest Output") {
                    actions.openItem(latestItem.id)
                }
                if latestItem.outputURL != nil {
                    Button("Reveal Latest Output") {
                        actions.revealOutput(latestItem.id)
                    }
                }
            }

            Divider()

            Button("Clear All") {
                actions.removeAllItems()
            }
        }
    }

    private var latestItem: QuickAccessItem? {
        items.first
    }

    private var stagedCount: Int {
        items.filter { $0.state == .staged }.count
    }

    private var activeCount: Int {
        items.filter { $0.state == .queued || $0.state == .processing }.count
    }

    private var completedCount: Int {
        items.filter { $0.state == .completed }.count
    }

    private var failedCount: Int {
        items.filter { $0.state == .failed }.count
    }

    private var finishedCount: Int {
        completedCount + failedCount
    }

    private var statusTitle: String {
        if stagedCount > 0 {
            return stagedCount == 1 ? "1 item ready" : "\(stagedCount) items ready"
        }
        if activeCount > 0 {
            return "\(finishedCount)/\(items.count) done"
        }
        if failedCount > 0 {
            return "\(completedCount)/\(items.count) done, \(failedCount) failed"
        }
        if completedCount == items.count {
            return "All items complete"
        }
        return "\(items.count) items"
    }

    private var optimizeTitle: String {
        guard stagedCount > 0 else { return "Optimize All" }
        return stagedCount == 1 ? "Optimize 1 Item" : "Optimize All \(stagedCount) Items"
    }
}

struct QuickAccessBoxActionsPopoverView: View {
    let items: [QuickAccessItem]
    let actions: QuickAccessPresentationActions

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            if stagedCount > 0 {
                actionButton(title: optimizeTitle, systemImage: "play.fill") {
                    actions.processAllStagedItems()
                }
            }

            if let latestItem {
                Divider()

                actionButton(
                    title: latestItem.outputURL == nil ? "Open Latest Original" : "Open Latest Output",
                    systemImage: "arrow.up.right.square"
                ) {
                    actions.openItem(latestItem.id)
                }

                if latestItem.outputURL != nil {
                    actionButton(title: "Reveal Latest Output", systemImage: "folder") {
                        actions.revealOutput(latestItem.id)
                    }
                }
            }

            Divider()

            actionButton(title: "Clear All", systemImage: "xmark.circle") {
                actions.removeAllItems()
            }
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
    }

    private func actionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 14)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var latestItem: QuickAccessItem? {
        items.first
    }

    private var stagedCount: Int {
        items.filter { $0.state == .staged }.count
    }

    private var activeCount: Int {
        items.filter { $0.state == .queued || $0.state == .processing }.count
    }

    private var completedCount: Int {
        items.filter { $0.state == .completed }.count
    }

    private var failedCount: Int {
        items.filter { $0.state == .failed }.count
    }

    private var finishedCount: Int {
        completedCount + failedCount
    }

    private var statusTitle: String {
        if stagedCount > 0 {
            return stagedCount == 1 ? "1 item ready" : "\(stagedCount) items ready"
        }
        if activeCount > 0 {
            return "\(finishedCount)/\(items.count) done"
        }
        if failedCount > 0 {
            return "\(completedCount)/\(items.count) done, \(failedCount) failed"
        }
        if completedCount == items.count {
            return "All items complete"
        }
        return "\(items.count) items"
    }

    private var optimizeTitle: String {
        stagedCount == 1 ? "Optimize 1 Item" : "Optimize All \(stagedCount) Items"
    }
}
