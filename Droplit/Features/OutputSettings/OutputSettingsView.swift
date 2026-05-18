import AppKit
import SwiftUI

struct OutputSettingsView: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @State private var saveLocationEnabled = OptimizationOutputSettings.saveLocationEnabled
    @State private var outputDirectory = OptimizationOutputSettings.outputDirectory
    @State private var temporaryRetentionDays = OptimizationOutputSettings.temporaryRetentionDays

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Output")
                    .font(.headline)

                Spacer()

                Toggle("Save location", isOn: saveLocationBinding)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            HStack(spacing: 10) {
                Image(systemName: saveLocationEnabled ? "folder.fill" : "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(saveLocationEnabled ? .blue : .orange)
                    .frame(width: 30, height: 30)
                    .background(
                        (saveLocationEnabled ? Color.blue : Color.orange).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 8)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(destinationName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Text(destinationPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if saveLocationEnabled {
                    Spacer(minLength: 6)

                    Button {
                        chooseOutputDirectory()
                    } label: {
                        Image(systemName: "folder.badge.gearshape")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Choose output folder")
                }
            }

            if !saveLocationEnabled {
                Stepper(
                    value: retentionBinding,
                    in: OptimizationOutputSettings.allowedTemporaryRetentionDays
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.purple)
                            .frame(width: 30, height: 30)
                            .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete after")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)

                            Text(retentionText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Picker("On conversion", selection: $quickAccess.conversionOutputMode) {
                ForEach(ConversionOutputMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(10)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
        .onAppear {
            refreshState()
        }
    }

    private var saveLocationBinding: Binding<Bool> {
        Binding(
            get: { saveLocationEnabled },
            set: { newValue in
                saveLocationEnabled = newValue
                OptimizationOutputSettings.saveLocationEnabled = newValue
                if !newValue {
                    OptimizationTemporaryFileStore.cleanupExpiredOutputsInBackground(retentionDays: temporaryRetentionDays)
                }
            }
        )
    }

    private var retentionBinding: Binding<Int> {
        Binding(
            get: { temporaryRetentionDays },
            set: { newValue in
                let clamped = OptimizationOutputSettings.clampTemporaryRetentionDays(newValue)
                temporaryRetentionDays = clamped
                OptimizationOutputSettings.temporaryRetentionDays = clamped
                OptimizationTemporaryFileStore.cleanupExpiredOutputsInBackground(retentionDays: clamped)
            }
        )
    }

    private var destinationName: String {
        if saveLocationEnabled {
            return OptimizationOutputSettings.displayName(for: outputDirectory)
        }
        return "Temporary storage"
    }

    private var destinationPath: String {
        if saveLocationEnabled {
            return outputDirectory.path
        }
        return OptimizationTemporaryFileStore.outputDirectory.path
    }

    private var retentionText: String {
        temporaryRetentionDays == 1 ? "1 day" : "\(temporaryRetentionDays) days"
    }

    private func refreshState() {
        saveLocationEnabled = OptimizationOutputSettings.saveLocationEnabled
        outputDirectory = OptimizationOutputSettings.outputDirectory
        temporaryRetentionDays = OptimizationOutputSettings.temporaryRetentionDays
    }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose Output Folder"
        panel.message = "Optimized files will be saved here."
        panel.prompt = "Choose"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = outputDirectory

        guard panel.runModal() == .OK, let url = panel.url else { return }
        OptimizationOutputSettings.outputDirectory = url
        outputDirectory = url
    }
}
