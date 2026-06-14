import AppKit

@MainActor
enum QuickAccessExternalDragSession {
    static func begin(
        fileURL: URL,
        thumbnail: NSImage,
        onEnded: @escaping @MainActor (Bool) -> Void
    ) -> Bool {
        begin(fileURLs: [fileURL], thumbnail: thumbnail, onEnded: onEnded)
    }

    static func begin(
        fileURLs: [URL],
        thumbnail: NSImage,
        onEnded: @escaping @MainActor (Bool) -> Void
    ) -> Bool {
        let existingFileURLs = fileURLs.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !existingFileURLs.isEmpty,
              let event = NSApp.currentEvent,
              let contentView = dragContentView(for: event) else {
            return false
        }

        let dragID = UUID()
        let source = QuickAccessExternalDraggingSource(dragID: dragID) { success in
            Task { @MainActor in
                QuickAccessExternalDragRegistry.release(for: dragID)
                onEnded(success)
            }
        }
        QuickAccessExternalDragRegistry.retain(source, for: dragID)

        let dragImage = makeDragImage(from: thumbnail, count: existingFileURLs.count)
        let mouseLocation = contentView.convert(event.locationInWindow, from: nil)
        let dragItems = existingFileURLs.enumerated().map { index, fileURL in
            let dragItem = NSDraggingItem(pasteboardWriter: fileURL as NSURL)
            let offset = CGFloat(index) * 4
            dragItem.setDraggingFrame(
                NSRect(
                    x: mouseLocation.x - dragImage.size.width / 2 + offset,
                    y: mouseLocation.y - dragImage.size.height / 2 - offset,
                    width: dragImage.size.width,
                    height: dragImage.size.height
                ),
                contents: dragImage
            )
            return dragItem
        }

        let session = contentView.beginDraggingSession(
            with: dragItems,
            event: event,
            source: source
        )
        session.animatesToStartingPositionsOnCancelOrFail = true
        return true
    }

    private static func dragContentView(for event: NSEvent) -> NSView? {
        if let contentView = event.window?.contentView {
            return contentView
        }
        if let contentView = NSApp.keyWindow?.contentView {
            return contentView
        }
        return NSApp.windows.first(where: \.isVisible)?.contentView
    }

    private static func makeDragImage(from thumbnail: NSImage, count: Int) -> NSImage {
        let imageSize = dragImageSize(for: thumbnail.size)
        let image = NSImage(size: imageSize)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        thumbnail.draw(
            in: NSRect(origin: .zero, size: imageSize),
            from: .zero,
            operation: .sourceOver,
            fraction: 0.84
        )
        if count > 1 {
            drawCountBadge(count, in: imageSize)
        }
        image.unlockFocus()
        return image
    }

    private static func drawCountBadge(_ count: Int, in imageSize: NSSize) {
        let label = "\(count)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let textSize = label.size(withAttributes: attributes)
        let badgeSize = NSSize(width: max(textSize.width + 12, 22), height: 20)
        let badgeRect = NSRect(
            x: imageSize.width - badgeSize.width - 3,
            y: imageSize.height - badgeSize.height - 3,
            width: badgeSize.width,
            height: badgeSize.height
        )

        NSColor.black.withAlphaComponent(0.62).setFill()
        NSBezierPath(roundedRect: badgeRect, xRadius: 10, yRadius: 10).fill()

        label.draw(
            in: NSRect(
                x: badgeRect.midX - textSize.width / 2,
                y: badgeRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            ),
            withAttributes: attributes
        )
    }

    private static func dragImageSize(for sourceSize: NSSize) -> NSSize {
        let fallback = NSSize(width: 112, height: 72)
        guard sourceSize.width > 0, sourceSize.height > 0 else { return fallback }

        let maximumSize = NSSize(width: 116, height: 76)
        let scale = min(maximumSize.width / sourceSize.width, maximumSize.height / sourceSize.height)
        return NSSize(
            width: max(sourceSize.width * scale, 40),
            height: max(sourceSize.height * scale, 40)
        )
    }
}

private final class QuickAccessExternalDraggingSource: NSObject, NSDraggingSource {
    let dragID: UUID
    private let onEnded: (Bool) -> Void

    init(dragID: UUID, onEnded: @escaping (Bool) -> Void) {
        self.dragID = dragID
        self.onEnded = onEnded
        super.init()
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        onEnded(operation != [])
    }
}

@MainActor
private enum QuickAccessExternalDragRegistry {
    private static var activeSources: [UUID: QuickAccessExternalDraggingSource] = [:]

    static func retain(_ source: QuickAccessExternalDraggingSource, for id: UUID) {
        activeSources[id] = source
    }

    static func release(for id: UUID) {
        activeSources[id] = nil
    }
}
