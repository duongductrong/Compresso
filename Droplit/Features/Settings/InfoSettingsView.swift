import SwiftUI

struct InfoSettingsView: View {
    let section: DroplitSettingsSection

    var body: some View {
        DroplitSettingsPage(
            title: section.title,
            subtitle: section.subtitle
        ) {
            pageContent
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch section {
        case .appearance:
            DroplitSettingsGroup(
                "Presentation",
                description: "Droplit now follows standard macOS split-view and settings window conventions."
            ) {
                DroplitSettingsValueRow(
                    title: "Window Style",
                    subtitle: "Uses NavigationSplitView, native sidebar selection, and the standard toolbar.",
                    value: "Native"
                )
                DroplitSettingsDivider()
                DroplitSettingsValueRow(
                    title: "Color and Material",
                    subtitle: "System materials, semantic text colors, and the current macOS accent are used automatically.",
                    value: "Adaptive"
                )
            }
        case .privacy:
            DroplitSettingsGroup(
                "Local Processing",
                description: "All optimization work is executed on this Mac with local tools."
            ) {
                DroplitSettingsValueRow(
                    title: "File Handling",
                    subtitle: "Dropped or imported files stay on-device unless you move them elsewhere.",
                    value: "On Device"
                )
                DroplitSettingsDivider()
                DroplitSettingsValueRow(
                    title: "Network Use",
                    subtitle: "No cloud upload or remote optimization service is required.",
                    value: "Offline"
                )
            }
        case .advanced:
            DroplitSettingsGroup(
                "Defaults",
                description: "Persistent preferences and failure handling for power users."
            ) {
                DroplitSettingsValueRow(
                    title: "Preferences",
                    subtitle: "Quick Access, output destination, and retention settings are stored in user defaults.",
                    value: "Persistent"
                )
                DroplitSettingsDivider()
                DroplitSettingsValueRow(
                    title: "Tool Recovery",
                    subtitle: "Missing optimizers surface in Tools instead of silently falling back.",
                    value: "Visible"
                )
            }
        case .about:
            DroplitSettingsGroup(
                "Application",
                description: "Current build information for the running app."
            ) {
                DroplitSettingsValueRow(
                    title: "Version",
                    subtitle: "Short version and build number",
                    value: versionDescription
                )
                DroplitSettingsDivider()
                DroplitSettingsValueRow(
                    title: "Bundle Identifier",
                    subtitle: "Useful for logging and defaults domains",
                    value: bundleIdentifier
                )
            }
            DroplitSettingsGroup(
                "Behavior",
                description: "What Droplit optimizes and how it behaves on this Mac."
            ) {
                DroplitSettingsValueRow(
                    title: "Processing Model",
                    subtitle: "Quick media optimization powered by local CLI tools.",
                    value: "Local"
                )
                DroplitSettingsDivider()
                DroplitSettingsValueRow(
                    title: "Output Model",
                    subtitle: "Supports a chosen folder or managed temporary storage.",
                    value: "Flexible"
                )
            }
        default:
            DroplitSettingsGroup("Details") {
                DroplitSettingsValueRow(
                    title: primaryTitle,
                    subtitle: primarySubtitle,
                    value: "Enabled"
                )
                DroplitSettingsDivider()
                DroplitSettingsValueRow(
                    title: secondaryTitle,
                    subtitle: secondarySubtitle,
                    value: "Ready"
                )
            }
        }
    }

    private var primaryTitle: String {
        switch section {
        case .appearance: "Native Appearance"
        case .privacy: "Local Processing"
        case .advanced: "Advanced Defaults"
        default: "Droplit"
        }
    }

    private var primarySubtitle: String {
        switch section {
        case .appearance: "Uses system materials, accent color, and SF Symbols."
        case .privacy: "Media optimization runs through local tools on your Mac."
        case .advanced: "Core optimization behavior stays controlled by feature panels."
        default: "Quick media optimization for macOS."
        }
    }

    private var secondaryTitle: String {
        switch section {
        case .privacy: "No Cloud Upload"
        case .about: "Status"
        default: "System Integrated"
        }
    }

    private var secondarySubtitle: String {
        switch section {
        case .privacy: "Files stay local unless you move them into another app."
        case .about: "Debug build from the local workspace."
        default: "Follows the current macOS control and window style."
        }
    }

    private var versionDescription: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(shortVersion) (\(buildNumber))"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
}
