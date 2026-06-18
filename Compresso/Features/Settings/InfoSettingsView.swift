import AppKit
import SwiftUI
import Sparkle

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
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 4)

                heroSection

                sponsorSection

                footerSection

                Spacer()
                    .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
        default:
            EmptyView()
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

            VStack(spacing: 4) {
                Text(appName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text(appSlogan)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Text("Version \(versionDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastCheck = UpdaterManager.shared.updater.lastUpdateCheckDate {
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Checked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastCheck, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.05))
            .clipShape(Capsule())

            HStack(spacing: 8) {
                if #available(macOS 12.0, *) {
                    Button(action: { UpdaterManager.shared.checkForUpdates() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Check for Updates")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button(action: {
                        if let url = URL(string: "https://github.com/duongductrong/Compresso/issues") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Report a Problem")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                } else {
                    Button("Check for Updates") {
                        UpdaterManager.shared.checkForUpdates()
                    }
                    Button("Report a Problem") {
                        if let url = URL(string: "https://github.com/duongductrong/Compresso/issues") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }

    private var sponsorSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Support Compresso")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(sponsorLinks.enumerated()), id: \.element.id) { index, link in
                    SponsorRowView(link: link)

                    if index < sponsorLinks.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            Text("Compresso is open-source. Sponsor if it helps your workflow.")
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: 420)
    }

    private var footerSection: some View {
        HStack(spacing: 16) {
            Link(destination: URL(string: "https://github.com/duongductrong/Compresso")!) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Website")

            Link(destination: URL(string: "https://github.com/duongductrong")!) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("GitHub")

            Link(destination: URL(string: "https://github.com/duongductrong/Compresso/issues")!) {
                Image(systemName: "ant.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Report a Bug")
        }
        .padding(.top, 4)
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
        "Native macOS media optimizer"
    }
}
