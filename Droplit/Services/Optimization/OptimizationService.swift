import AppKit
import Foundation

struct OptimizationResult {
    let outputURL: URL
    let originalBytes: Int64
    let optimizedBytes: Int64
    let pixelSize: CGSize?
}

struct OptimizationTool: Identifiable {
    let id: String
    let name: String
    let command: String
    let brewPackage: String
    let role: String
    let systemImage: String

    var isAvailable: Bool {
        OptimizationToolResolver.executable(named: command) != nil
    }

    static let catalog: [OptimizationTool] = [
        OptimizationTool(id: "pngquant", name: "pngquant", command: "pngquant", brewPackage: "pngquant", role: "PNG", systemImage: "photo"),
        OptimizationTool(id: "jpegoptim", name: "jpegoptim", command: "jpegoptim", brewPackage: "jpegoptim", role: "JPEG", systemImage: "camera"),
        OptimizationTool(id: "gifsicle", name: "gifsicle", command: "gifsicle", brewPackage: "gifsicle", role: "GIF", systemImage: "sparkles"),
        OptimizationTool(id: "ffmpeg", name: "ffmpeg", command: "ffmpeg", brewPackage: "ffmpeg", role: "Video", systemImage: "video"),
        OptimizationTool(id: "vips", name: "libvips", command: "vips", brewPackage: "vips", role: "Resize", systemImage: "arrow.down.right.and.arrow.up.left"),
        OptimizationTool(id: "gifski", name: "gifski", command: "gifski", brewPackage: "gifski", role: "Video to GIF", systemImage: "film.stack"),
        OptimizationTool(id: "gs", name: "ghostscript", command: "gs", brewPackage: "ghostscript", role: "PDF", systemImage: "doc.richtext")
    ]
}

enum OptimizationError: LocalizedError {
    case unsupportedType
    case missingTool(String)
    case commandFailed(String)
    case outputMissing

    var errorDescription: String? {
        switch self {
        case .unsupportedType:
            return "Unsupported file"
        case .missingTool(let tool):
            return "\(tool) not found"
        case .commandFailed(let message):
            return message.isEmpty ? "Optimizer failed" : message
        case .outputMissing:
            return "Output missing"
        }
    }
}

enum OptimizationService {
    static func optimize(sourceURL: URL, kind: QuickAccessFileKind) async throws -> OptimizationResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try optimizeSynchronously(sourceURL: sourceURL, kind: kind)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func optimizeSynchronously(sourceURL: URL, kind: QuickAccessFileKind) throws -> OptimizationResult {
        guard kind.isSupported else { throw OptimizationError.unsupportedType }

        let originalBytes = fileSize(at: sourceURL)
        let outputURL = try makeOutputURL(for: sourceURL, kind: kind)

        switch kind {
        case .png:
            try runPNGQuant(sourceURL: sourceURL, outputURL: outputURL)
        case .jpeg:
            try runJPEGOptim(sourceURL: sourceURL, outputURL: outputURL)
        case .gif:
            try runGifsicle(sourceURL: sourceURL, outputURL: outputURL)
        case .video:
            try runFFmpeg(sourceURL: sourceURL, outputURL: outputURL)
        case .pdf:
            try runGhostscript(sourceURL: sourceURL, outputURL: outputURL)
        case .image:
            try runVips(sourceURL: sourceURL, outputURL: outputURL)
        case .unknown:
            throw OptimizationError.unsupportedType
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw OptimizationError.outputMissing
        }

        return OptimizationResult(
            outputURL: outputURL,
            originalBytes: originalBytes,
            optimizedBytes: fileSize(at: outputURL),
            pixelSize: NSImage(contentsOf: outputURL)?.pixelSizeForOptimization
        )
    }

    private static func runPNGQuant(sourceURL: URL, outputURL: URL) throws {
        let executable = try requiredExecutable("pngquant")
        do {
            try run(
                executable,
                arguments: [
                    "--force",
                    "--skip-if-larger",
                    "--quality", "65-95",
                    "--output", outputURL.path,
                    sourceURL.path
                ]
            )
        } catch {
            if !FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: outputURL)
            }
            return
        }
        if !FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        }
    }

    private static func runJPEGOptim(sourceURL: URL, outputURL: URL) throws {
        let executable = try requiredExecutable("jpegoptim")
        try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        try run(
            executable,
            arguments: [
                "--strip-all",
                "--max=85",
                outputURL.path
            ]
        )
    }

    private static func runGifsicle(sourceURL: URL, outputURL: URL) throws {
        let executable = try requiredExecutable("gifsicle")
        try run(
            executable,
            arguments: [
                "-O3",
                sourceURL.path,
                "-o",
                outputURL.path
            ]
        )
    }

    private static func runFFmpeg(sourceURL: URL, outputURL: URL) throws {
        let executable = try requiredExecutable("ffmpeg")
        try run(
            executable,
            arguments: [
                "-y",
                "-i", sourceURL.path,
                "-map_metadata", "-1",
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "28",
                "-c:a", "aac",
                "-b:a", "128k",
                outputURL.path
            ]
        )
    }

    private static func runGhostscript(sourceURL: URL, outputURL: URL) throws {
        let executable = try requiredExecutable("gs")
        try run(
            executable,
            arguments: [
                "-sDEVICE=pdfwrite",
                "-dCompatibilityLevel=1.4",
                "-dPDFSETTINGS=/ebook",
                "-dNOPAUSE",
                "-dQUIET",
                "-dBATCH",
                "-sOutputFile=\(outputURL.path)",
                sourceURL.path
            ]
        )
    }

    private static func runVips(sourceURL: URL, outputURL: URL) throws {
        let executable = try requiredExecutable("vips")
        try run(
            executable,
            arguments: [
                "thumbnail",
                sourceURL.path,
                outputURL.path,
                "2560",
                "--size", "down"
            ]
        )
    }

    private static func makeOutputURL(for sourceURL: URL, kind: QuickAccessFileKind) throws -> URL {
        let directory = try outputDirectory()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let suffix = UUID().uuidString.prefix(8)
        let pathExtension: String

        switch kind {
        case .video:
            pathExtension = "mp4"
        case .image:
            pathExtension = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        default:
            pathExtension = sourceURL.pathExtension
        }

        return directory
            .appendingPathComponent("\(baseName)-optimized-\(suffix)")
            .appendingPathExtension(pathExtension)
    }

    private static func outputDirectory() throws -> URL {
        let root = OptimizationOutputSettings.outputDirectory
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func requiredExecutable(_ name: String) throws -> URL {
        guard let url = OptimizationToolResolver.executable(named: name) else {
            throw OptimizationError.missingTool(name)
        }
        return url
    }

    private static func run(_ executableURL: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw OptimizationError.commandFailed(message)
        }
    }

    private static func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }
}

enum OptimizationToolResolver {
    static let searchPaths = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/opt/homebrew/sbin",
        "/usr/local/sbin",
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin"
    ]

    static var pathEnvironmentValue: String {
        searchPaths.joined(separator: ":")
    }

    static func executable(named name: String) -> URL? {
        for directory in searchPaths {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }
}

struct HomebrewBootstrapResult {
    let requestedPackages: [String]
    let stillMissingTools: [OptimizationTool]

    var installedEverything: Bool {
        stillMissingTools.isEmpty
    }
}

enum HomebrewBootstrapError: LocalizedError {
    case homebrewMissing
    case installFailed(String)

    var errorDescription: String? {
        switch self {
        case .homebrewMissing:
            return "Homebrew not found"
        case .installFailed(let message):
            return message.isEmpty ? "Homebrew install failed" : message
        }
    }
}

enum HomebrewBootstrapService {
    static var homebrewURL: URL? {
        OptimizationToolResolver.executable(named: "brew")
    }

    static var isHomebrewAvailable: Bool {
        homebrewURL != nil
    }

    static func missingTools() -> [OptimizationTool] {
        OptimizationTool.catalog.filter { !$0.isAvailable }
    }

    static func installMissingTools() async throws -> HomebrewBootstrapResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try installMissingToolsSynchronously()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func installMissingToolsSynchronously() throws -> HomebrewBootstrapResult {
        let missingTools = missingTools()
        guard !missingTools.isEmpty else {
            return HomebrewBootstrapResult(requestedPackages: [], stillMissingTools: [])
        }

        guard let homebrewURL else {
            throw HomebrewBootstrapError.homebrewMissing
        }

        let packages = Array(Set(missingTools.map(\.brewPackage))).sorted()
        try runHomebrew(homebrewURL, arguments: ["install"] + packages)

        return HomebrewBootstrapResult(
            requestedPackages: packages,
            stillMissingTools: self.missingTools()
        )
    }

    private static func runHomebrew(_ executableURL: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = OptimizationToolResolver.pathEnvironmentValue
        environment["HOMEBREW_NO_ENV_HINTS"] = "1"
        environment["NONINTERACTIVE"] = "1"
        process.environment = environment

        let logURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Droplit-Homebrew-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let logHandle = try FileHandle(forWritingTo: logURL)
        defer {
            try? logHandle.close()
            try? FileManager.default.removeItem(at: logURL)
        }

        process.standardOutput = logHandle
        process.standardError = logHandle

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            try? logHandle.synchronize()
            let message = (try? String(contentsOf: logURL, encoding: .utf8))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
            throw HomebrewBootstrapError.installFailed(message)
        }
    }
}

private extension NSImage {
    var pixelSizeForOptimization: CGSize? {
        guard let representation = representations.max(by: { $0.pixelsWide < $1.pixelsWide }) else {
            return nil
        }
        return CGSize(width: representation.pixelsWide, height: representation.pixelsHigh)
    }
}
