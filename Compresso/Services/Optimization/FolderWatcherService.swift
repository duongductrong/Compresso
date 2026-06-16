import Foundation
import Combine
import SwiftUI

@MainActor
final class FolderWatcherService: ObservableObject {
    static let shared = FolderWatcherService()

    @Published private(set) var isWatching = false

    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.ghosted.compresso.folderwatcher", qos: .default)
    private var watchedFiles: Set<URL> = []

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

        let fd = open(folder.path, O_EVTONLY)
        guard fd != -1 else {
            return
        }
        self.fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: queue
        )

        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                await self.handleFolderContentsChanged()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        self.dispatchSource = source
        source.resume()
        isWatching = true
    }

    func stop() {
        isWatching = false
        dispatchSource?.cancel()
        dispatchSource = nil
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
        watchedFiles.removeAll()
    }

    private func scanFolder(_ folder: URL) -> Set<URL> {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            var files = Set<URL>()
            for url in urls {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue {
                    files.insert(url.standardizedFileURL)
                }
            }
            return files
        } catch {
            return []
        }
    }

    private func handleFolderContentsChanged() async {
        guard let folder = OptimizationOutputSettings.watchedFolderURL else { return }
        let currentFiles = scanFolder(folder)

        // Find new files
        let newFiles = currentFiles.subtracting(watchedFiles)
        
        // Update local cache
        watchedFiles = currentFiles

        guard !newFiles.isEmpty else { return }

        for file in newFiles {
            let kind = QuickAccessFileKind.detect(from: file)
            guard kind.isSupported else { continue }

            let filename = file.lastPathComponent
            // Prevent self-trigger loops
            if filename.contains("-optimized-") || filename.contains("-converted-") {
                continue
            }

            // Wait for file completion in background, then import
            Task {
                let isReady = await waitUntilFileIsReady(file)
                if isReady {
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
        }
    }

    private func waitUntilFileIsReady(_ file: URL) async -> Bool {
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
