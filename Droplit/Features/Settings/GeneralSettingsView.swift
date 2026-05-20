import SwiftUI

struct GeneralSettingsView: View {
    @Binding var selection: DroplitSettingsSection
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var isImporting: Bool

    var body: some View {
        DroplitSettingsPage(
            title: DroplitSettingsSection.general.title,
            subtitle: "Manage Quick Access, output, tools, and media optimization from a single native macOS settings surface."
        ) {
            DroplitSettingsGroup(
                "Overview",
                description: "High-level app status and related system pages."
            ) {
                DroplitSettingsNavigationRow(
                    section: .about,
                    subtitle: "Version, build, and app details"
                ) {
                    selection = .about
                }
                DroplitSettingsDivider()
                DroplitSettingsNavigationRow(
                    section: .tools,
                    subtitle: toolStatusText
                ) {
                    selection = .tools
                }
                DroplitSettingsDivider()
                DroplitSettingsNavigationRow(
                    title: DroplitSettingsSection.storage.title,
                    subtitle: outputSummary
                ) {
                    selection = .output
                }
            }

            DroplitSettingsGroup(
                "Workflow",
                description: "Core behavior for Quick Access, output, conversions, and job capacity."
            ) {
                DroplitSettingsNavigationRow(
                    section: .quickAccess,
                    subtitle: quickAccessSummary
                ) {
                    selection = .quickAccess
                }
                DroplitSettingsDivider()
                DroplitSettingsNavigationRow(
                    section: .output,
                    subtitle: "Save location, retention, and folder picker"
                ) {
                    selection = .output
                }
                DroplitSettingsDivider()
                DroplitSettingsNavigationRow(
                    title: DroplitSettingsSection.conversion.title,
                    subtitle: quickAccess.conversionOutputMode.displayName
                ) {
                    selection = .output
                }
                DroplitSettingsDivider()
                DroplitSettingsNavigationRow(
                    title: DroplitSettingsSection.concurrency.title,
                    subtitle: "\(quickAccess.maximumConcurrentOptimizations) parallel jobs"
                ) {
                    selection = .quickAccess
                }
            }

            DroplitSettingsGroup(
                "Actions",
                description: "Open media optimization or import files without leaving settings."
            ) {
                DroplitSettingsControlRow(
                    title: "Optimize Files",
                    subtitle: "Import files directly into media optimization"
                ) {
                    Button("Choose...") {
                        isImporting = true
                    }
                }
                DroplitSettingsDivider()
                DroplitSettingsNavigationRow(
                    section: .queue,
                    subtitle: queueSummaryText
                ) {
                    selection = .queue
                }
            }
        }
    }

    private var quickAccessSummary: String {
        "\(quickAccess.triggerInteraction.displayName), \(quickAccess.position.edge.displayName.lowercased()) \(quickAccess.position.alignment.displayName.lowercased())"
    }

    private var outputSummary: String {
        if OptimizationOutputSettings.saveLocationEnabled {
            return OptimizationOutputSettings.displayName(for: OptimizationOutputSettings.outputDirectory)
        }
        return "Temporary storage, \(OptimizationOutputSettings.temporaryRetentionDays)d retention"
    }

    private var toolStatusText: String {
        let missingCount = HomebrewBootstrapService.missingTools().count
        if missingCount == 0 {
            return "All dependencies ready"
        }
        return "\(missingCount) missing dependencies"
    }

    private var queueSummaryText: String {
        guard !quickAccess.items.isEmpty else { return "No jobs yet" }
        let parts = [
            quickAccess.processingCount > 0 ? "\(quickAccess.processingCount) running" : nil,
            quickAccess.stagedCount > 0 ? "\(quickAccess.stagedCount) ready" : nil,
            quickAccess.queuedCount > 0 ? "\(quickAccess.queuedCount) queued" : nil
        ].compactMap { $0 }
        return parts.isEmpty ? "\(quickAccess.items.count) total" : parts.joined(separator: ", ")
    }
}
