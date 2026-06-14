import SwiftUI

struct ToolsSettingsView: View {
    @State private var toolRefreshID = UUID()
    @State private var isInstallingTools = false
    @State private var toolBootstrapMessage: String?
    @State private var processingToolIDs: Set<String> = []

    var body: some View {
        CompressoSettingsPage(
            title: CompressoSettingsSection.tools.title,
            subtitle: "Check local dependency binaries and install missing Homebrew packages when available."
        ) {
            CompressoSettingsGroup(
                "Status",
                description: "Compresso uses local command-line tools for each optimization format."
            ) {
                CompressoSettingsControlRow(
                    title: "Dependency Status",
                    subtitle: toolBootstrapMessage ?? toolStatusText
                ) {
                    toolBootstrapControl
                }
            }

            CompressoSettingsGroup(
                "Installed Tools",
                description: "Availability is checked against the current machine, not a bundled copy."
            ) {
                ForEach(Array(OptimizationTool.catalog.enumerated()), id: \.element.id) { index, tool in
                    toolRow(tool)
                    if index < OptimizationTool.catalog.count - 1 {
                        CompressoSettingsDivider()
                    }
                }
            }
            .id(toolRefreshID)
        }
    }

    @ViewBuilder
    private var toolBootstrapControl: some View {
        if isInstallingTools {
            ProgressView()
                .controlSize(.small)
        } else if missingTools.isEmpty {
            Image(systemName: "checkmark.circle.fill")
                .font(.body.weight(.semibold))
                .foregroundColor(.green)
                .help("All dependencies ready")
        } else {
            Button("Install") {
                Task {
                    await installMissingTools()
                }
            }
            .disabled(!HomebrewBootstrapService.isHomebrewAvailable)
            .help(HomebrewBootstrapService.isHomebrewAvailable ? "Install missing dependencies" : "Homebrew not found")
        }
    }

    private func toolRow(_ tool: OptimizationTool) -> some View {
        CompressoSettingsAlignedRow(
            title: tool.name,
            subtitle: tool.role
        ) {
            if processingToolIDs.contains(tool.id) {
                ProgressView()
                    .controlSize(.small)
            } else if tool.isAvailable {
                Button("Uninstall") {
                    Task {
                        await uninstallSingleTool(tool)
                    }
                }
                .disabled(!HomebrewBootstrapService.isHomebrewAvailable)
            } else {
                Button("Install") {
                    Task {
                        await installSingleTool(tool)
                    }
                }
                .disabled(!HomebrewBootstrapService.isHomebrewAvailable)
            }
        }
    }

    private var missingTools: [OptimizationTool] {
        HomebrewBootstrapService.missingTools()
    }

    private var toolStatusText: String {
        let count = missingTools.count
        if isInstallingTools {
            return "Installing missing dependencies"
        } else if count == 0 {
            return "All dependencies ready"
        } else if !HomebrewBootstrapService.isHomebrewAvailable {
            return "\(count) missing; Homebrew not found"
        } else {
            return "\(count) missing"
        }
    }

    @MainActor
    private func installMissingTools() async {
        let missingBeforeInstall = missingTools
        guard !missingBeforeInstall.isEmpty else {
            toolBootstrapMessage = "All dependencies ready"
            toolRefreshID = UUID()
            return
        }

        isInstallingTools = true
        toolBootstrapMessage = "Installing \(missingBeforeInstall.count) missing dependencies"
        defer {
            isInstallingTools = false
            toolRefreshID = UUID()
        }

        do {
            let result = try await HomebrewBootstrapService.installMissingTools()
            if result.installedEverything {
                toolBootstrapMessage = result.requestedPackages.isEmpty
                    ? "All dependencies ready"
                    : "Installed \(result.requestedPackages.joined(separator: ", "))"
            } else {
                toolBootstrapMessage = "Still missing \(toolNames(result.stillMissingTools))"
            }
        } catch {
            toolBootstrapMessage = shortToolMessage(error.localizedDescription)
        }
    }

    @MainActor
    private func installSingleTool(_ tool: OptimizationTool) async {
        guard !processingToolIDs.contains(tool.id) else { return }
        processingToolIDs.insert(tool.id)
        defer {
            processingToolIDs.remove(tool.id)
            toolRefreshID = UUID()
        }

        do {
            try await HomebrewBootstrapService.installTool(tool)
            toolBootstrapMessage = "Installed \(tool.name)"
        } catch {
            toolBootstrapMessage = shortToolMessage(error.localizedDescription)
        }
    }

    @MainActor
    private func uninstallSingleTool(_ tool: OptimizationTool) async {
        guard !processingToolIDs.contains(tool.id) else { return }
        processingToolIDs.insert(tool.id)
        defer {
            processingToolIDs.remove(tool.id)
            toolRefreshID = UUID()
        }

        do {
            try await HomebrewBootstrapService.uninstallTool(tool)
            toolBootstrapMessage = "Uninstalled \(tool.name)"
        } catch {
            toolBootstrapMessage = shortToolMessage(error.localizedDescription)
        }
    }

    private func toolNames(_ tools: [OptimizationTool]) -> String {
        tools.map(\.name).joined(separator: ", ")
    }

    private func shortToolMessage(_ message: String) -> String {
        let firstLine = message
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? message
        return String(firstLine.prefix(140))
    }
}
