import AppKit
import SwiftUI

struct QuickAccessBoxItemsPopoverView: View {
    let items: [QuickAccessItem]
    let actions: QuickAccessPresentationActions

    private let columns = Array(
        repeating: GridItem(.fixed(92), spacing: 10, alignment: .leading),
        count: 3
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    ForEach(items) { item in
                        QuickAccessBoxItemGridCell(item: item, actions: actions)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 260)
        }
        .padding(14)
        .frame(width: 326)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            Text("\(items.count) \(items.count == 1 ? "Item" : "Items")")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Text(summaryText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private var summaryText: String {
        let staged = items.filter { $0.state == .staged }.count
        if staged > 0 {
            return "\(staged) ready"
        }
        let processing = items.filter { $0.state == .processing }.count
        let queued = items.filter { $0.state == .queued }.count
        let completed = items.filter { $0.state == .completed }.count
        let failed = items.filter { $0.state == .failed }.count
        if processing + queued > 0 {
            return "\(completed + failed)/\(items.count) done"
        }
        if let batchSizeComparisonText {
            return batchSizeComparisonText
        }
        if failed > 0 {
            return "\(completed)/\(items.count) done"
        }
        return completed == items.count ? "All done" : "Batch"
    }

    private var batchSizeComparisonText: String? {
        let outputItems = items.filter { item in
            guard item.state == .completed,
                  item.optimizedBytes != nil,
                  let outputURL = item.outputURL else {
                return false
            }
            return FileManager.default.fileExists(atPath: outputURL.path)
        }
        guard !outputItems.isEmpty else { return nil }

        let originalBytes = outputItems.reduce(Int64(0)) { $0 + $1.originalBytes }
        let optimizedBytes = outputItems.reduce(Int64(0)) { $0 + ($1.optimizedBytes ?? $1.originalBytes) }
        return "\(ByteCountFormatter.droplitString(fromByteCount: originalBytes)) -> \(ByteCountFormatter.droplitString(fromByteCount: optimizedBytes))"
    }
}

private struct QuickAccessBoxItemGridCell: View {
    let item: QuickAccessItem
    let actions: QuickAccessPresentationActions

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            thumbnail

            Text(item.displayTitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            metadataLine

            sizeLine
        }
        .frame(width: 92, height: 110, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture(count: 2) {
            actions.openItem(item.id)
        }
        .onDrag {
            dragItemProvider
        }
        .help(helpText)
        .quickAccessCursor(.pointingHand)
        .accessibilityElement(children: .combine)
        .accessibilityHint(helpText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            actions.openItem(item.id)
        }
    }

    private var thumbnail: some View {
        Image(nsImage: item.thumbnail)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 92, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var sizeLine: some View {
        Text(sizeText)
            .font(.system(size: 8.5, weight: .regular, design: .rounded))
            .foregroundColor(.secondary.opacity(0.86))
            .droplitMonospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }

    private var metadataLine: some View {
        HStack(spacing: 3) {
            Text(fileTypeText)
                .lineLimit(1)
            Text("/")
                .foregroundColor(.secondary.opacity(0.72))
            Text(statusText)
                .foregroundColor(statusColor)
                .lineLimit(1)
        }
        .font(.system(size: 8.5, weight: .regular))
        .foregroundColor(.secondary)
        .lineLimit(1)
    }

    private var fileTypeText: String {
        let pathExtension = item.sourceURL.pathExtension.uppercased()
        return pathExtension.isEmpty ? item.kind.displayName.uppercased() : pathExtension
    }

    private var sizeText: String {
        item.optimizedBytes == nil ? item.originalSizeText : item.sizeComparisonText
    }

    private var dragItemProvider: NSItemProvider {
        guard let preferredExternalDragURL = item.preferredExternalDragURL else {
            return NSItemProvider()
        }
        return NSItemProvider(object: preferredExternalDragURL as NSURL)
    }

    private var helpText: String {
        if item.usesOptimizedExternalDragURL {
            return "Double-click to open preview, or drag optimized output"
        }
        return "Double-click to open original, or drag original file"
    }

    private var statusText: String {
        switch item.state {
        case .staged:
            return "Ready"
        case .queued:
            return "Queued"
        case .processing:
            return "Running"
        case .completed:
            return "Done"
        case .failed:
            return "Failed"
        }
    }

    private var statusColor: Color {
        switch item.state {
        case .completed:
            return .green
        case .failed:
            return .orange
        case .processing:
            return .accentColor
        case .staged, .queued:
            return .secondary
        }
    }
}
