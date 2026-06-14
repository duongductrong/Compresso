import AppKit
import SwiftUI

struct InfoSettingsView: View {
    let section: CompressoSettingsSection

    var body: some View {
        CompressoSettingsPage(
            title: section.title,
            subtitle: section.subtitle,
            showsHeader: section != .about
        ) {
            pageContent
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch section {
        case .about:
            aboutHeader

            CompressoSettingsGroup(
                "Application",
                description: "Current build information for the running app."
            ) {
                CompressoSettingsValueRow(
                    title: "Version",
                    subtitle: "Short version and build number",
                    value: versionDescription
                )
                CompressoSettingsDivider()
                CompressoSettingsValueRow(
                    title: "Bundle Identifier",
                    subtitle: "Useful for logging and defaults domains",
                    value: bundleIdentifier
                )
                CompressoSettingsDivider()
                CompressoSettingsControlRow(
                    title: "Check for Updates",
                    subtitle: "Compresso verifies signed releases before installing."
                ) {
                    Button("Check for Updates") {
                        UpdaterManager.shared.checkForUpdates()
                    }
                }
            }
        default:
            EmptyView()
        }
    }

    private var aboutHeader: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 104, height: 104)

            VStack(alignment: .center, spacing: 4) {
                Text(appName)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(appSlogan)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var versionDescription: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(shortVersion) (\(buildNumber))"
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Compresso"
    }

    private var appSlogan: String {
        "Quick media optimization for macOS."
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
}
