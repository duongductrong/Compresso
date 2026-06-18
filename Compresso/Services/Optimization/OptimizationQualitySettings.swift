//
//  OptimizationQualitySettings.swift
//  Compresso
//
//  User-configurable quality parameters for optimization tools.
//

import Foundation

/// ffmpeg x264 encoder preset. Slower presets yield smaller files at the same CRF.
enum FFmpegPreset: String, CaseIterable, Identifiable {
    case ultrafast
    case superfast
    case veryfast
    case faster
    case fast
    case medium
    case slow
    case slower
    case veryslow

    var id: String { rawValue }

    /// Label shown in the UI.
    var displayName: String {
        rawValue.capitalized
    }
}

/// Audio bitrate for ffmpeg encodes.
enum VideoAudioBitrate: Int, CaseIterable, Identifiable {
    case k64 = 64
    case k96 = 96
    case k128 = 128
    case k160 = 160
    case k192 = 192
    case k256 = 256
    case k320 = 320

    var id: Int { rawValue }

    /// ffmpeg `-b:a` token, e.g. `"128k"`.
    var cliToken: String {
        "\(rawValue)k"
    }

    /// Label shown in the UI, e.g. `"128 kbps"`.
    var displayName: String {
        "\(rawValue) kbps"
    }
}

/// Ghostscript `-dPDFSETTINGS` quality preset.
/// Lower presets produce smaller, lower-resolution PDFs.
enum PDFPreset: String, CaseIterable, Identifiable {
    case screen
    case ebook
    case printer
    case prepress
    case `default`

    var id: String { rawValue }

    /// Ghostscript CLI token, e.g. `"/ebook"`.
    var cliToken: String {
        "/\(rawValue)"
    }

    /// Human-readable description shown in the UI.
    var displayName: String {
        switch self {
        case .screen:
            "Low (72 dpi)"
        case .ebook:
            "Medium (150 dpi)"
        case .printer:
            "High (300 dpi)"
        case .prepress:
            "Max (300 dpi, color preserve)"
        case .default:
            "General purpose"
        }
    }
}

nonisolated enum OptimizationQualitySettings {
    private static let imageQualityKey = "optimization.imageQuality"
    private static let videoQualityKey = "optimization.videoQuality"
    private static let imageMaxWidthKey = "optimization.imageMaxWidth"
    private static let imageStripMetadataKey = "optimization.imageStripMetadata"
    private static let videoEncoderPresetKey = "optimization.videoEncoderPreset"
    private static let videoAudioBitrateKey = "optimization.videoAudioBitrate"
    private static let gifsicleOptimizationLevelKey = "optimization.gifsicleOptimizationLevel"
    private static let gifFrameRateKey = "optimization.gifFrameRate"
    private static let gifMaxWidthKey = "optimization.gifMaxWidth"
    private static let pdfPresetKey = "optimization.pdfPreset"

    static let allowedImageQualityRange = 10...100
    static let allowedVideoQualityRange = 18...51
    static let allowedImageMaxWidthRange = 512...8192
    static let allowedGifsicleOptimizationLevelRange = 1...3
    static let allowedGifFrameRateRange = 5...30
    static let allowedGifMaxWidthRange = 240...1280

    // MARK: - Image / Video scalars

    /// Image quality setting (10–100). Used by pngquant, jpegoptim, vips, gifski.
    /// Higher values produce better quality and larger files.
    static var imageQuality: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: imageQualityKey)
            return saved > 0 ? clampImageQuality(saved) : 85
        }
        set {
            UserDefaults.standard.set(clampImageQuality(newValue), forKey: imageQualityKey)
        }
    }

    /// Video quality CRF value (18–51). Used by ffmpeg.
    /// Lower values produce better quality and larger files.
    static var videoQuality: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: videoQualityKey)
            return saved > 0 ? clampVideoQuality(saved) : 28
        }
        set {
            UserDefaults.standard.set(clampVideoQuality(newValue), forKey: videoQualityKey)
        }
    }

    // MARK: - Image extra knobs

    /// Maximum width (px) for vips thumbnail downscale on image optimization.
    static var imageMaxWidth: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: imageMaxWidthKey)
            return saved > 0 ? clampImageMaxWidth(saved) : 2560
        }
        set {
            UserDefaults.standard.set(clampImageMaxWidth(newValue), forKey: imageMaxWidthKey)
        }
    }

    /// Whether jpegoptim should strip all metadata (`--strip-all`).
    static var imageStripMetadata: Bool {
        get {
            // Object lookup so unset → default true (preserves prior behavior).
            if UserDefaults.standard.object(forKey: imageStripMetadataKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: imageStripMetadataKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: imageStripMetadataKey)
        }
    }

    // MARK: - Video extra knobs

    /// ffmpeg x264 encoder preset.
    static var videoEncoderPreset: FFmpegPreset {
        get {
            if let raw = UserDefaults.standard.string(forKey: videoEncoderPresetKey),
               let value = FFmpegPreset(rawValue: raw) {
                return value
            }
            return .medium
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: videoEncoderPresetKey)
        }
    }

    /// ffmpeg audio bitrate.
    static var videoAudioBitrate: VideoAudioBitrate {
        get {
            let saved = UserDefaults.standard.integer(forKey: videoAudioBitrateKey)
            return VideoAudioBitrate(rawValue: saved) ?? .k128
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: videoAudioBitrateKey)
        }
    }

    // MARK: - GIF knobs

    /// gifsicle optimization level (`-O`).
    static var gifsicleOptimizationLevel: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: gifsicleOptimizationLevelKey)
            return saved > 0 ? clampGifsicleOptimizationLevel(saved) : 3
        }
        set {
            UserDefaults.standard.set(clampGifsicleOptimizationLevel(newValue), forKey: gifsicleOptimizationLevelKey)
        }
    }

    /// Target frame rate for video→GIF conversion (gifski `--fps` / ffmpeg `fps=`).
    static var gifFrameRate: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: gifFrameRateKey)
            return saved > 0 ? clampGifFrameRate(saved) : 15
        }
        set {
            UserDefaults.standard.set(clampGifFrameRate(newValue), forKey: gifFrameRateKey)
        }
    }

    /// Maximum width (px) for video→GIF conversion (gifski `--width` / ffmpeg `scale=`).
    static var gifMaxWidth: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: gifMaxWidthKey)
            return saved > 0 ? clampGifMaxWidth(saved) : 720
        }
        set {
            UserDefaults.standard.set(clampGifMaxWidth(newValue), forKey: gifMaxWidthKey)
        }
    }

    // MARK: - PDF knobs

    /// Ghostscript `-dPDFSETTINGS` preset.
    static var pdfPreset: PDFPreset {
        get {
            if let raw = UserDefaults.standard.string(forKey: pdfPresetKey),
               let value = PDFPreset(rawValue: raw) {
                return value
            }
            return .ebook
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: pdfPresetKey)
        }
    }

    // MARK: - PNG quality range for pngquant

    /// Returns the `--quality` range string for pngquant (e.g. "65-95").
    static var pngQualityRange: String {
        let q = imageQuality
        let minQ = max(q - 20, 0)
        return "\(minQ)-\(q)"
    }

    // MARK: - Clamping

    static func clampImageQuality(_ value: Int) -> Int {
        min(max(value, allowedImageQualityRange.lowerBound), allowedImageQualityRange.upperBound)
    }

    static func clampVideoQuality(_ value: Int) -> Int {
        min(max(value, allowedVideoQualityRange.lowerBound), allowedVideoQualityRange.upperBound)
    }

    static func clampImageMaxWidth(_ value: Int) -> Int {
        min(max(value, allowedImageMaxWidthRange.lowerBound), allowedImageMaxWidthRange.upperBound)
    }

    static func clampGifsicleOptimizationLevel(_ value: Int) -> Int {
        min(max(value, allowedGifsicleOptimizationLevelRange.lowerBound), allowedGifsicleOptimizationLevelRange.upperBound)
    }

    static func clampGifFrameRate(_ value: Int) -> Int {
        min(max(value, allowedGifFrameRateRange.lowerBound), allowedGifFrameRateRange.upperBound)
    }

    static func clampGifMaxWidth(_ value: Int) -> Int {
        min(max(value, allowedGifMaxWidthRange.lowerBound), allowedGifMaxWidthRange.upperBound)
    }
}
