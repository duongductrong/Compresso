import AppKit
import AVFoundation
import PDFKit

struct QuickAccessThumbnailResult {
    let image: NSImage
    let pixelSize: CGSize?
    let duration: TimeInterval?
}

enum QuickAccessThumbnailGenerator {
    static func generate(from url: URL, kind: QuickAccessFileKind) async -> QuickAccessThumbnailResult {
        switch kind {
        case .video:
            return await generateVideoThumbnail(from: url)
        case .pdf:
            return await generateOffMain {
                generatePDFThumbnail(from: url)
            }
        case .png, .jpeg, .gif, .image:
            return await generateOffMain {
                generateImageThumbnail(from: url, fallbackKind: kind)
            }
        case .unknown:
            return QuickAccessThumbnailResult(
                image: placeholderThumbnail(systemImage: kind.systemImage),
                pixelSize: nil,
                duration: nil
            )
        }
    }

    private static func generateOffMain(_ work: @escaping () -> QuickAccessThumbnailResult) async -> QuickAccessThumbnailResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: work())
            }
        }
    }

    private static func generateImageThumbnail(from url: URL, fallbackKind: QuickAccessFileKind) -> QuickAccessThumbnailResult {
        guard let image = NSImage(contentsOf: url) else {
            return QuickAccessThumbnailResult(
                image: placeholderThumbnail(systemImage: fallbackKind.systemImage),
                pixelSize: nil,
                duration: nil
            )
        }

        return QuickAccessThumbnailResult(
            image: image.scaledToFit(maxDimension: 320),
            pixelSize: image.pixelSize,
            duration: nil
        )
    }

    private static func generatePDFThumbnail(from url: URL) -> QuickAccessThumbnailResult {
        guard let document = PDFDocument(url: url), let page = document.page(at: 0) else {
            return QuickAccessThumbnailResult(
                image: placeholderThumbnail(systemImage: "doc.richtext.fill"),
                pixelSize: nil,
                duration: nil
            )
        }

        let bounds = page.bounds(for: .mediaBox)
        let thumbnail = page.thumbnail(of: CGSize(width: 360, height: 240), for: .mediaBox)
        return QuickAccessThumbnailResult(
            image: thumbnail,
            pixelSize: CGSize(width: bounds.width, height: bounds.height),
            duration: nil
        )
    }

    private static func generateVideoThumbnail(from url: URL) async -> QuickAccessThumbnailResult {
        let asset = AVURLAsset(url: url)
        let duration: TimeInterval?
        do {
            let loadedDuration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(loadedDuration)
            duration = durationSeconds.isFinite ? durationSeconds : nil
        } catch {
            duration = nil
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 360)

        do {
            let (cgImage, _) = try await generator.image(at: CMTime(seconds: 0.1, preferredTimescale: 600))
            let image = NSImage(cgImage: cgImage, size: .zero)
            return QuickAccessThumbnailResult(
                image: image.scaledToFit(maxDimension: 320),
                pixelSize: CGSize(width: cgImage.width, height: cgImage.height),
                duration: duration
            )
        } catch {
            return QuickAccessThumbnailResult(
                image: placeholderThumbnail(systemImage: "video.fill"),
                pixelSize: nil,
                duration: duration
            )
        }
    }

    static func placeholderThumbnail(systemImage: String) -> NSImage {
        let size = NSSize(width: 320, height: 200)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.black.withAlphaComponent(0.84).setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 18, yRadius: 18).fill()

        let symbol = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        symbol?.draw(
            in: NSRect(x: 132, y: 72, width: 56, height: 56),
            from: .zero,
            operation: .sourceOver,
            fraction: 0.75
        )
        image.unlockFocus()
        return image
    }
}

private extension NSImage {
    var pixelSize: CGSize? {
        guard let representation = representations.max(by: { $0.pixelsWide < $1.pixelsWide }) else {
            return nil
        }
        return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
    }

    func scaledToFit(maxDimension: CGFloat) -> NSImage {
        let sourceSize = size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return self }
        let scale = min(maxDimension / max(sourceSize.width, sourceSize.height), 1)
        guard scale < 1 else { return self }

        let newSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let output = NSImage(size: newSize)
        output.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: sourceSize),
            operation: .copy,
            fraction: 1
        )
        output.unlockFocus()
        return output
    }
}
