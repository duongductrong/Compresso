import AppKit
import SwiftUI

struct QuickAccessBoxView: View {
    let context: QuickAccessPresentationContext
    let actions: QuickAccessPresentationActions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTargeted = false
    @State private var isItemsPopoverPresented = false
    @State private var isBatchActionsPopoverPresented = false
    @State private var didBeginBatchOutputDrag = false
    @State private var isDraggingBatchOutputs = false

    private typealias Layout = QuickAccessBoxLayout

    var body: some View {
        VStack(spacing: 0) {
            if context.position.isTopEdge {
                boxSurface
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                boxSurface
            }
        }
        .padding(Layout.shadowMargin)
        .frame(width: Layout.panelSize.width, height: Layout.panelSize.height)
        .onChange(of: context.items.isEmpty) { isEmpty in
            if isEmpty {
                isItemsPopoverPresented = false
                isBatchActionsPopoverPresented = false
            }
        }
    }

    private var boxSurface: some View {
        ZStack {
            boxBackground

            if showsPreviewStack {
                previewStack
            } else {
                QuickAccessBoxEmptyStateView(
                    isTargeted: isTargeted,
                    hasPendingDropSummary: context.pendingDropSummary != nil
                )
                    .offset(y: -7)
            }

            if context.isDropPlaceholderVisible {
                QuickAccessDropReceiverView(isTargeted: $isTargeted) { urls in
                    actions.stageDroppedURLs(urls)
                }
                .frame(width: Layout.boxSize.width, height: Layout.boxSize.height)
            }

            chromeOverlay
        }
        .frame(width: Layout.boxSize.width, height: Layout.boxSize.height)
        .clipShape(boxShape)
        .overlay(boxBorder)
        .contentShape(boxShape)
        .contextMenu {
            QuickAccessBoxActionMenu(items: context.items, actions: actions)
        }
        .onTapGesture(count: 2) {
            if let item = latestItem {
                actions.openItem(item.id)
            }
        }
        .shadow(color: .black.opacity(isTargeted ? 0.32 : 0.24), radius: isTargeted ? 28 : 22, x: 0, y: 16)
        .shadow(color: .black.opacity(0.24), radius: 7, x: 0, y: 2)
        .animation(QuickAccessAnimations.hoverOverlay, value: isTargeted)
    }

    private var previewStack: some View {
        QuickAccessBoxPreviewView(items: context.items, isTargeted: isTargeted, reduceMotion: reduceMotion)
            .offset(y: -5)
            .contentShape(Rectangle())
            .gesture(batchOutputDragGesture)
            .opacity(isDraggingBatchOutputs ? 0.62 : 1)
    }

    private var boxBackground: some View {
        ZStack {
            boxShape.fill(Color(red: 0.115, green: 0.115, blue: 0.112))
            DroplitMaterialFill(shape: boxShape, kind: .regular, fallbackOpacity: 0.86)
                .opacity(0.18)
            boxShape.fill(.white.opacity(isTargeted ? 0.045 : 0.018))
        }
    }

    private var chromeOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                chromeButton(systemImage: "xmark") {
                    actions.removeAllItems()
                }
                .help(context.items.isEmpty ? "Close" : "Clear all items")

                Spacer()
                batchActionButton
            }
            .padding(Layout.chromeInset)

            Spacer(minLength: 0)
            if showsPreviewStack {
                countPill
                    .padding(.bottom, Layout.countPillBottomInset)
            }
        }
    }

    private var batchActionButton: some View {
        chromeButton(systemImage: topRightIcon) {
            guard !context.items.isEmpty else { return }
            isBatchActionsPopoverPresented.toggle()
        }
        .popover(isPresented: $isBatchActionsPopoverPresented) {
            QuickAccessBoxActionsPopoverView(items: context.items, actions: actions)
        }
        .help(topRightHelp)
    }

    private var countPill: some View {
        Button {
            if !context.items.isEmpty {
                isItemsPopoverPresented.toggle()
            }
        } label: {
            countPillContent
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isItemsPopoverPresented) {
            QuickAccessBoxItemsPopoverView(items: context.items, actions: actions)
        }
        .help(context.items.isEmpty ? "Drop items to inspect" : "Show dropped items")
    }

    private var countPillContent: some View {
        HStack(spacing: 7) {
            Text(countText)
                .font(.system(size: Layout.countFontSize, weight: .regular))
                .foregroundColor(.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Image(systemName: countPillIcon)
                .font(.system(size: showsPreviewStack ? 17 : 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.62))
        }
        .padding(.leading, 11)
        .padding(.trailing, 5)
        .frame(height: Layout.countPillHeight)
        .background(Capsule().fill(Color.white.opacity(0.105)))
    }

    private func chromeButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            chromeCircle(systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func chromeCircle(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(
                size: systemImage == "ellipsis" ? Layout.chromeMoreIconSize : Layout.chromeCloseIconSize,
                weight: .semibold
            ))
            .foregroundColor(.black.opacity(0.70))
            .frame(width: Layout.chromeButtonSize, height: Layout.chromeButtonSize)
            .background(Circle().fill(Color.white.opacity(0.68)))
            .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            .contentShape(Circle())
    }

    private var countText: String {
        let count = context.items.count
        guard count > 0 else {
            return context.pendingDropSummary?.displayText ?? (isTargeted ? "Release" : "Drop Items")
        }
        if activeItemCount > 0 {
            return "\(finishedItemCount)/\(count) Done"
        }
        if !hasStagedItems, let batchSizeComparisonText {
            return batchSizeComparisonText
        }
        if failedItemCount > 0 {
            return "\(completedItemCount)/\(count) Done"
        }
        if completedItemCount == count {
            return batchSizeComparisonText ?? "All Done"
        }
        return "\(count) \(itemNoun(for: count))"
    }

    private var countPillIcon: String {
        guard showsPreviewStack else { return "tray.and.arrow.down.fill" }
        if activeItemCount > 0 { return "clock.fill" }
        if failedItemCount > 0 { return "exclamationmark.circle.fill" }
        if completedItemCount == context.items.count { return "checkmark.circle.fill" }
        return "chevron.down.circle.fill"
    }

    private var topRightIcon: String {
        guard !context.items.isEmpty else { return "ellipsis" }
        if hasStagedItems { return "play.fill" }
        if activeItemCount > 0 { return "clock.fill" }
        if failedItemCount > 0 { return "exclamationmark" }
        if completedItemCount == context.items.count { return "checkmark" }
        return "ellipsis"
    }

    private var topRightHelp: String {
        if hasStagedItems { return "Choose batch action" }
        if activeItemCount > 0 { return "\(finishedItemCount) of \(context.items.count) finished" }
        if failedItemCount > 0 { return "\(failedItemCount) failed" }
        if completedItemCount == context.items.count, !context.items.isEmpty { return "All items complete" }
        return "No staged items"
    }

    private var hasStagedItems: Bool {
        context.items.contains { $0.state == .staged }
    }

    private var activeItemCount: Int {
        context.items.filter { $0.state == .queued || $0.state == .processing }.count
    }

    private var completedItemCount: Int {
        context.items.filter { $0.state == .completed }.count
    }

    private var failedItemCount: Int {
        context.items.filter { $0.state == .failed }.count
    }

    private var finishedItemCount: Int {
        completedItemCount + failedItemCount
    }

    private var batchOutputDragGesture: some Gesture {
        DragGesture(minimumDistance: 7)
            .onChanged { value in
                guard canDragBatchOutputs,
                      !didBeginBatchOutputDrag,
                      hypot(value.translation.width, value.translation.height) > 8 else {
                    return
                }
                beginBatchOutputDrag()
            }
            .onEnded { _ in
                didBeginBatchOutputDrag = false
            }
    }

    private func beginBatchOutputDrag() {
        let outputItems = completedOutputItems
        guard let thumbnail = outputItems.first?.thumbnail else { return }

        didBeginBatchOutputDrag = true
        isDraggingBatchOutputs = true
        let didBegin = QuickAccessExternalDragSession.begin(
            fileURLs: outputItems.compactMap(outputURL),
            thumbnail: thumbnail
        ) { success in
            didBeginBatchOutputDrag = false
            isDraggingBatchOutputs = false
            if success {
                outputItems.forEach { item in
                    actions.removeItem(item.id)
                }
            }
        }

        if !didBegin {
            didBeginBatchOutputDrag = false
            isDraggingBatchOutputs = false
        }
    }

    private var canDragBatchOutputs: Bool {
        !completedOutputItems.isEmpty
    }

    private var completedOutputItems: [QuickAccessItem] {
        context.items.filter { outputURL(for: $0) != nil }
    }

    private var batchSizeComparisonText: String? {
        let outputItems = completedOutputItems.filter { $0.optimizedBytes != nil }
        guard !outputItems.isEmpty else { return nil }

        let originalBytes = outputItems.reduce(Int64(0)) { $0 + $1.originalBytes }
        let optimizedBytes = outputItems.reduce(Int64(0)) { $0 + ($1.optimizedBytes ?? $1.originalBytes) }
        return "\(ByteCountFormatter.droplitString(fromByteCount: originalBytes)) -> \(ByteCountFormatter.droplitString(fromByteCount: optimizedBytes))"
    }

    private func outputURL(for item: QuickAccessItem) -> URL? {
        guard item.state == .completed,
              let outputURL = item.outputURL,
              FileManager.default.fileExists(atPath: outputURL.path) else {
            return nil
        }
        return outputURL
    }

    private var showsPreviewStack: Bool {
        !context.items.isEmpty
    }

    private func itemNoun(for count: Int) -> String {
        let singular = count == 1
        if context.items.allSatisfy(\.kind.isImageLike) { return singular ? "Image" : "Images" }
        if context.items.allSatisfy({ $0.kind == .video }) { return singular ? "Video" : "Videos" }
        if context.items.allSatisfy({ $0.kind == .pdf }) { return singular ? "PDF" : "PDFs" }
        return singular ? "File" : "Files"
    }

    private var latestItem: QuickAccessItem? { context.items.first }

    private var boxShape: RoundedRectangle { RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous) }

    private var boxBorder: some View {
        ZStack {
            boxShape.strokeBorder(.white.opacity(isTargeted ? 0.28 : 0.14), lineWidth: isTargeted ? 1.6 : 1.1)
            boxShape.strokeBorder(.black.opacity(0.46), lineWidth: 1).padding(1)
        }
    }
}

private extension QuickAccessFileKind {
    var isImageLike: Bool {
        switch self {
        case .png, .jpeg, .gif, .image:
            return true
        case .video, .pdf, .unknown:
            return false
        }
    }
}
