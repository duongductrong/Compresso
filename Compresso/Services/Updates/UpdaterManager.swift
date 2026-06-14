import Foundation
import OSLog
import Sparkle

final class UpdaterManager: NSObject, SPUUpdaterDelegate {
    static let shared = UpdaterManager()

    private let logger = Logger(subsystem: "com.trongduong.Compresso", category: "updates")
    private(set) var controller: SPUStandardUpdaterController!

    var updater: SPUUpdater {
        controller.updater
    }

    private override init() {
        super.init()
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        logger.info("Sparkle updater initialized")
    }

    func checkForUpdates() {
        logger.info("Manual update check requested")
        updater.checkForUpdates()
    }

    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        logger.info("Appcast loaded with \(appcast.items.count, privacy: .public) item(s)")
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        logger.info(
            "Update available: \(item.displayVersionString, privacy: .public) (\(item.versionString, privacy: .public))"
        )
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
        let nsError = error as NSError
        logger.warning(
            "No update found: \(nsError.localizedDescription, privacy: .public) [\(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)]"
        )
    }

    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        logger.info("Downloaded update: \(item.displayVersionString, privacy: .public)")
    }

    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        logger.info("Installing update: \(item.displayVersionString, privacy: .public)")
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        let nsError = error as NSError
        logger.error(
            "Update aborted: \(nsError.localizedDescription, privacy: .public) [\(nsError.domain, privacy: .public) \(nsError.code, privacy: .public)]"
        )
    }
}
