import AppKit
import Foundation
import UniformTypeIdentifiers

enum QuickAccessPosition: String, CaseIterable, Codable, Identifiable {
    case bottomLeft
    case bottomCenter
    case bottomRight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bottomLeft: "Left"
        case .bottomCenter: "Center"
        case .bottomRight: "Right"
        }
    }

    var systemImage: String {
        switch self {
        case .bottomLeft: "align.horizontal.left.fill"
        case .bottomCenter: "align.horizontal.center.fill"
        case .bottomRight: "align.horizontal.right.fill"
        }
    }

    var isLeftSide: Bool { self == .bottomLeft }
    var dismissDirection: CGFloat { isLeftSide ? -1 : 1 }

    func calculateOrigin(for size: CGSize, on screen: NSScreen, padding: CGFloat = 22) -> CGPoint {
        let frame = screen.visibleFrame
        let shadowMargin = QuickAccessLayout.shadowMargin
        switch self {
        case .bottomLeft:
            return CGPoint(x: frame.minX + padding - shadowMargin, y: frame.minY + padding - shadowMargin)
        case .bottomCenter:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.minY + padding - shadowMargin)
        case .bottomRight:
            return CGPoint(x: frame.maxX - size.width - padding + shadowMargin, y: frame.minY + padding - shadowMargin)
        }
    }

    func offscreenOrigin(for size: CGSize, on screen: NSScreen, padding: CGFloat = 22) -> CGPoint {
        let frame = screen.visibleFrame
        let margin: CGFloat = 48
        switch self {
        case .bottomLeft:
            return CGPoint(x: frame.minX - size.width - margin, y: frame.minY + padding)
        case .bottomCenter:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.minY - size.height - margin)
        case .bottomRight:
            return CGPoint(x: frame.maxX + margin, y: frame.minY + padding)
        }
    }
}

enum QuickAccessTriggerInteraction: String, CaseIterable, Codable, Identifiable {
    case shake
    case hold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shake: "Shake"
        case .hold: "Hold"
        }
    }

    var systemImage: String {
        switch self {
        case .shake: "waveform.path.ecg"
        case .hold: "timer"
        }
    }
}

enum QuickAccessLayout {
    static let cardWidth: CGFloat = 184
    static let cardHeight: CGFloat = 118
    static let overflowCardHeight: CGFloat = cardHeight
    static let cornerRadius: CGFloat = 14
    static let cardSpacing: CGFloat = 10
    static let shadowMargin: CGFloat = 44
    static let containerPadding: CGFloat = shadowMargin
    static let maximumFloatingItems = 4

    static func panelSize(itemCardCount: Int, includesOverflowCard: Bool) -> CGSize {
        let visibleCount = max(itemCardCount + (includesOverflowCard ? 1 : 0), 1)
        let itemHeight = cardHeight * CGFloat(itemCardCount)
        let overflowHeight = includesOverflowCard ? overflowCardHeight : 0
        let height = itemHeight + overflowHeight
            + (cardSpacing * CGFloat(max(visibleCount - 1, 0)))
            + (containerPadding * 2)
        return CGSize(width: cardWidth + containerPadding * 2, height: height)
    }
}

enum QuickAccessJobState: Equatable {
    case queued
    case processing
    case completed
    case failed
}

enum QuickAccessFileKind: String, CaseIterable, Codable {
    case png
    case jpeg
    case gif
    case video
    case pdf
    case image
    case unknown

    static let importableContentTypes: [UTType] = [
        .png,
        .jpeg,
        .gif,
        .image,
        .movie,
        .mpeg4Movie,
        .quickTimeMovie,
        .pdf
    ]

    static func detect(from url: URL) -> QuickAccessFileKind {
        switch url.pathExtension.lowercased() {
        case "png": .png
        case "jpg", "jpeg": .jpeg
        case "gif": .gif
        case "mov", "mp4", "m4v", "avi", "mkv", "webm": .video
        case "pdf": .pdf
        case "heic", "heif", "tif", "tiff", "webp": .image
        default: .unknown
        }
    }

    var isSupported: Bool { self != .unknown }

    var displayName: String {
        switch self {
        case .png: "PNG"
        case .jpeg: "JPEG"
        case .gif: "GIF"
        case .video: "Video"
        case .pdf: "PDF"
        case .image: "Image"
        case .unknown: "File"
        }
    }

    var systemImage: String {
        switch self {
        case .png, .jpeg, .image: "photo.fill"
        case .gif: "sparkles"
        case .video: "video.fill"
        case .pdf: "doc.richtext.fill"
        case .unknown: "doc.fill"
        }
    }
}

struct QuickAccessItem: Identifiable {
    let id: UUID
    let sourceURL: URL
    let kind: QuickAccessFileKind
    let thumbnail: NSImage
    let createdAt: Date
    let originalBytes: Int64
    let mediaDuration: TimeInterval?
    var state: QuickAccessJobState
    var elapsed: TimeInterval
    var progress: Double?
    var optimizedBytes: Int64?
    var outputURL: URL?
    var pixelSize: CGSize?
    var failureMessage: String?

    init(
        sourceURL: URL,
        kind: QuickAccessFileKind,
        thumbnail: NSImage,
        originalBytes: Int64,
        mediaDuration: TimeInterval?,
        pixelSize: CGSize?
    ) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.kind = kind
        self.thumbnail = thumbnail
        self.createdAt = Date()
        self.originalBytes = originalBytes
        self.mediaDuration = mediaDuration
        self.pixelSize = pixelSize
        self.state = .queued
        self.elapsed = 0
        self.progress = nil
        self.optimizedBytes = nil
        self.outputURL = nil
        self.failureMessage = nil
    }

    var originalSizeText: String {
        ByteCountFormatter.droplitString(fromByteCount: originalBytes)
    }

    var optimizedSizeText: String {
        ByteCountFormatter.droplitString(fromByteCount: optimizedBytes ?? originalBytes)
    }

    var displayTitle: String {
        let title = sourceURL.deletingPathExtension().lastPathComponent
        return title.isEmpty ? sourceURL.lastPathComponent : title
    }

    var dimensionsText: String {
        guard let pixelSize, pixelSize.width > 0, pixelSize.height > 0 else {
            return kind.displayName
        }
        return "\(Int(pixelSize.width))x\(Int(pixelSize.height))"
    }

    var detailLine: String {
        switch state {
        case .queued:
            return "Queued"
        case .processing:
            if let mediaDuration, mediaDuration > 0 {
                return "\(elapsed.timecode3) of \(mediaDuration.timecode3)"
            }
            return "Optimizing \(elapsed.timecode3)"
        case .completed:
            return "\(originalSizeText) -> \(optimizedSizeText)"
        case .failed:
            return failureMessage ?? "Failed"
        }
    }
}

extension ByteCountFormatter {
    static func droplitString(fromByteCount bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes).replacingOccurrences(of: " ", with: "")
    }
}

extension TimeInterval {
    var timecode3: String {
        String(format: "%.3fs", self)
    }
}
