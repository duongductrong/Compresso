import Foundation

struct DroplitSettingsSidebarGroup: Identifiable {
    let title: String
    let sections: [DroplitSettingsSection]

    var id: String { title }
}

enum DroplitSettingsSection: String, CaseIterable, Identifiable {
    case general
    case quickAccess
    case output
    case conversion
    case tools
    case queue
    case concurrency
    case storage
    case appearance
    case privacy
    case advanced
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .quickAccess: "Quick Access"
        case .output: "Output"
        case .conversion: "Conversion"
        case .tools: "Tools"
        case .queue: "Queue"
        case .concurrency: "Concurrency"
        case .storage: "Storage"
        case .appearance: "Appearance"
        case .privacy: "Privacy"
        case .advanced: "Advanced"
        case .about: "About Droplit"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "Overview and shortcuts"
        case .quickAccess: "Trigger, placement, and concurrency"
        case .output: "Save location, storage, and conversion output"
        case .conversion: "How converted files are written"
        case .tools: "Optimizer availability and Homebrew install"
        case .queue: "Current and recent optimization jobs"
        case .concurrency: "Parallel optimization limits"
        case .storage: "Temporary output retention"
        case .appearance: "Window, material, and control style"
        case .privacy: "Local processing and file handling"
        case .advanced: "Power-user defaults and recovery"
        case .about: "Version, build, and app details"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape.fill"
        case .quickAccess: "sparkles.rectangle.stack.fill"
        case .output: "folder.fill"
        case .conversion: "arrow.triangle.2.circlepath"
        case .tools: "wrench.and.screwdriver.fill"
        case .queue: "tray.full.fill"
        case .concurrency: "bolt.horizontal.circle.fill"
        case .storage: "internaldrive.fill"
        case .appearance: "circle.lefthalf.filled"
        case .privacy: "hand.raised.fill"
        case .advanced: "slider.horizontal.3"
        case .about: "info.circle.fill"
        }
    }

    var searchText: String {
        "\(title) \(subtitle) \(searchKeywords) \(rawValue)"
    }

    var canonicalSection: DroplitSettingsSection {
        switch self {
        case .conversion, .storage:
            .output
        case .concurrency:
            .quickAccess
        default:
            self
        }
    }

    private var searchKeywords: String {
        switch self {
        case .quickAccess:
            "concurrency jobs hold shake alignment edge"
        case .output:
            "conversion storage retention folder temporary destination"
        default:
            ""
        }
    }

    static let sidebarGroups: [DroplitSettingsSidebarGroup] = [
        DroplitSettingsSidebarGroup(
            title: "Setup",
            sections: [.general, .quickAccess, .output]
        ),
        DroplitSettingsSidebarGroup(
            title: "Activity",
            sections: [.tools, .queue]
        ),
        DroplitSettingsSidebarGroup(
            title: "Application",
            sections: [.appearance, .privacy, .advanced, .about]
        )
    ]

    func matches(_ query: String) -> Bool {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedQuery.isEmpty else { return true }
        return searchText.localizedCaseInsensitiveContains(cleanedQuery)
    }
}
