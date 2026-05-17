import Foundation

enum OptimizationOutputSettings {
    private static let outputDirectoryKey = "optimization.outputDirectory"

    static var outputDirectory: URL {
        get {
            guard let path = UserDefaults.standard.string(forKey: outputDirectoryKey),
                  !path.isEmpty else {
                return desktopDirectory
            }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set {
            UserDefaults.standard.set(newValue.standardizedFileURL.path, forKey: outputDirectoryKey)
        }
    }

    static func displayName(for url: URL) -> String {
        let standardized = url.standardizedFileURL
        if standardized.path == desktopDirectory.standardizedFileURL.path {
            return "Desktop"
        }
        return standardized.lastPathComponent.isEmpty ? standardized.path : standardized.lastPathComponent
    }

    private static var desktopDirectory: URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop", isDirectory: true)
    }
}
