import Foundation

enum ConversionOutputMode: String, CaseIterable, Codable, Identifiable {
    case replace
    case duplicate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .replace: "Replace original"
        case .duplicate: "Create new file"
        }
    }

    var systemImage: String {
        switch self {
        case .replace: "arrow.2.circlepath"
        case .duplicate: "doc.on.doc"
        }
    }
}

enum OptimizationOutputSettings {
    private static let outputDirectoryKey = "optimization.outputDirectory"
    private static let conversionOutputModeKey = "optimization.conversionOutputMode"

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

    static var conversionOutputMode: ConversionOutputMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: conversionOutputModeKey),
                  let mode = ConversionOutputMode(rawValue: raw) else {
                return .duplicate
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: conversionOutputModeKey)
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
