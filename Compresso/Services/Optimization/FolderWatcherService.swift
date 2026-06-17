import Foundation
import Combine
import SwiftUI
import CoreServices

@MainActor
final class FolderWatcherService: ObservableObject {
    static let shared = FolderWatcherService()

    @Published private(set) var isWatching = false

    private var streamRef: FSEventStreamRef?
    private var watchedFiles: Set<URL> = []
    private var processingFiles: Set<URL> = []

    private init() {}

    func start() {
        stop()

        guard OptimizationOutputSettings.watchedFolderEnabled,
              let folder = OptimizationOutputSettings.watchedFolderURL else {
            return
        }

        // Verify directory exists
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir), isDir.boolValue else {
            return
        }

        // Populate initial file set to avoid double-processing already-present files
        watchedFiles = scanFolder(folder)
        processingFiles.removeAll()

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [folder.path as NSString] as CFArray

        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let clientCallBackInfo = clientCallBackInfo else { return }
            let service = Unmanaged<FolderWatcherService>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
            Task { @MainActor in
                await service.handleFolderContentsChanged()
            }
        }

        guard let stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0, // Latency in seconds
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        ) else {
            return
        }

        self.streamRef = stream
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        isWatching = true
    }

    func stop() {
        isWatching = false
        if let stream = streamRef {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            streamRef = nil
        }
        watchedFiles.removeAll()
        processingFiles.removeAll()
    }

    private func scanFolder(_ folder: URL) -> Set<URL> {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var files = Set<URL>()
        for case let url as URL in enumerator {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    files.insert(url.standardizedFileURL)
                }
            } catch {
                // Ignore individual file errors
            }
        }
        return files
    }

    private func handleFolderContentsChanged() async {
        guard let folder = OptimizationOutputSettings.watchedFolderURL else { return }
        let currentFiles = scanFolder(folder)

        // Find new files that are not already watched or being processed
        let newFiles = currentFiles.subtracting(watchedFiles).subtracting(processingFiles)

        // Update watchedFiles to only keep existing files (remove deleted ones)
        watchedFiles = currentFiles.intersection(watchedFiles)

        guard !newFiles.isEmpty else { return }

        for file in newFiles {
            let kind = QuickAccessFileKind.detect(from: file)
            guard kind.isSupported else {
                watchedFiles.insert(file)
                continue
            }

            let filename = file.lastPathComponent
            // Prevent self-trigger loops
            if filename.contains("-optimized-") || filename.contains("-converted-") {
                watchedFiles.insert(file)
                continue
            }

            // Mark as processing
            processingFiles.insert(file)

            // Wait for file completion in background, then import
            Task {
                let isReady = await waitUntilFileIsReady(file)
                await self.didFinishCheckingFile(file, isReady: isReady)
            }
        }
    }

    private func didFinishCheckingFile(_ file: URL, isReady: Bool) {
        guard isWatching else { return }
        processingFiles.remove(file)

        if isReady {
            watchedFiles.insert(file)

            // Check if already in queue to prevent double import
            let manager = QuickAccessManager.shared
            let alreadyQueued = manager.items.contains { item in
                item.sourceURL.standardizedFileURL == file.standardizedFileURL ||
                item.outputURL?.standardizedFileURL == file.standardizedFileURL
            }
            if !alreadyQueued {
                manager.ingestDroppedURLs([file])
            }
        }
    }

    nonisolated private func waitUntilFileIsReady(_ file: URL) async -> Bool {
        var prevSize: Int64 = -1
        var retries = 0
        while retries < 15 {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms sleep
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? Int64 {
                    if size == prevSize && size > 0 {
                        // File size has stabilized
                        return true
                    }
                    prevSize = size
                }
            } catch {
                // File might not be readable yet
            }
            retries += 1
        }
        return false
    }
}
