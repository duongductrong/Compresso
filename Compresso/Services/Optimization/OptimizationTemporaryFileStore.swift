import Foundation

nonisolated enum OptimizationTemporaryFileStore {
    static var outputDirectory: URL {
        appSupportDirectory
            .appendingPathComponent("Temporary Outputs", isDirectory: true)
    }

    static var droppedInputDirectory: URL {
        appSupportDirectory
            .appendingPathComponent("Temporary Drops", isDirectory: true)
    }

    static func makeJobOutputDirectory() throws -> URL {
        let root = try ensureOutputDirectory()
        let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func ensureOutputDirectory() throws -> URL {
        try ensureDirectory(outputDirectory)
    }

    static func ensureDroppedInputDirectory() throws -> URL {
        try ensureDirectory(droppedInputDirectory)
    }

    static func cleanupExpiredOutputsInBackground(retentionDays: Int = OptimizationOutputSettings.temporaryRetentionDays) {
        let clampedDays = OptimizationOutputSettings.clampTemporaryRetentionDays(retentionDays)
        Task.detached(priority: .utility) {
            cleanupExpiredOutputs(retentionDays: clampedDays)
        }
    }

    static func cleanupExpiredOutputs(retentionDays: Int, now: Date = Date()) {
        let clampedDays = OptimizationOutputSettings.clampTemporaryRetentionDays(retentionDays)
        let cutoff = now.addingTimeInterval(-Double(clampedDays) * 24 * 60 * 60)

        cleanupContents(in: outputDirectory, olderThan: cutoff)
        cleanupContents(in: droppedInputDirectory, olderThan: cutoff)
    }

    private static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)

        return base.appendingPathComponent("Compresso", isDirectory: true)
    }

    @discardableResult
    private static func ensureDirectory(_ directory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func cleanupContents(in directory: URL, olderThan cutoff: Date) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for url in contents where fileDate(for: url).map({ $0 < cutoff }) == true {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func fileDate(for url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        return values?.creationDate ?? values?.contentModificationDate
    }
}
