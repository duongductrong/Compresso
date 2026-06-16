import Foundation

nonisolated enum ConversionOutputMode: String, CaseIterable, Codable, Identifiable {
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

nonisolated enum OptimizationOutputDestinationKind {
    case userLocation
    case temporary
}

nonisolated struct OptimizationOutputDestination {
    let kind: OptimizationOutputDestinationKind
    let directory: URL
}

nonisolated enum OptimizationOutputSettings {
    static let allowedTemporaryRetentionDays = 1...90

    private static let outputDirectoryKey = "optimization.outputDirectory"
    private static let conversionOutputModeKey = "optimization.conversionOutputMode"
    private static let saveLocationEnabledKey = "optimization.saveLocationEnabled"
    private static let temporaryRetentionDaysKey = "optimization.temporaryRetentionDays"
    private static let optimizationOutputModeKey = "optimization.optimizationOutputMode"
    private static let watchedFolderPathKey = "optimization.watchedFolderPath"
    private static let watchedFolderEnabledKey = "optimization.watchedFolderEnabled"

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

    static var optimizationOutputMode: ConversionOutputMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: optimizationOutputModeKey),
                  let mode = ConversionOutputMode(rawValue: raw) else {
                return .duplicate
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: optimizationOutputModeKey)
        }
    }

    static var saveLocationEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: saveLocationEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: saveLocationEnabledKey)
        }
    }

    static var temporaryRetentionDays: Int {
        get {
            let savedDays = UserDefaults.standard.integer(forKey: temporaryRetentionDaysKey)
            return savedDays > 0 ? clampTemporaryRetentionDays(savedDays) : 1
        }
        set {
            UserDefaults.standard.set(clampTemporaryRetentionDays(newValue), forKey: temporaryRetentionDaysKey)
        }
    }

    static var watchedFolderURL: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: watchedFolderPathKey),
                  !path.isEmpty else {
                return nil
            }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set {
            if let url = newValue {
                UserDefaults.standard.set(url.standardizedFileURL.path, forKey: watchedFolderPathKey)
            } else {
                UserDefaults.standard.removeObject(forKey: watchedFolderPathKey)
            }
        }
    }

    static var watchedFolderEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: watchedFolderEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: watchedFolderEnabledKey)
        }
    }

    static var outputDestination: OptimizationOutputDestination {
        if saveLocationEnabled {
            return OptimizationOutputDestination(
                kind: .userLocation,
                directory: outputDirectory
            )
        }

        return OptimizationOutputDestination(
            kind: .temporary,
            directory: OptimizationTemporaryFileStore.outputDirectory
        )
    }

    static func clampTemporaryRetentionDays(_ days: Int) -> Int {
        min(max(days, allowedTemporaryRetentionDays.lowerBound), allowedTemporaryRetentionDays.upperBound)
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
