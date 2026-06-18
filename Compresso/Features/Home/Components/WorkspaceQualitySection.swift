//
//  WorkspaceQualitySection.swift
//  Compresso
//
//  Per-format quality configuration rendered as disclosure groups in the
//  workspace sidebar. Writes directly to OptimizationQualitySettings.
//

import SwiftUI

enum QualityFormatType: String, CaseIterable, Identifiable {
    case images = "Images"
    case video = "Video"
    case gif = "GIF"
    case pdf = "PDF"

    var id: String { self.rawValue }
}

struct WorkspaceQualitySection: View {
    @ObservedObject var quickAccess: QuickAccessManager

    @State private var selectedFormat: QualityFormatType = .images
    @State private var autoDetectedIds: Set<UUID> = []

    // Images
    @State private var imageQuality: Double = Double(OptimizationQualitySettings.imageQuality)
    @State private var imageMaxWidth: Double = Double(OptimizationQualitySettings.imageMaxWidth)
    @State private var imageStripMetadata = OptimizationQualitySettings.imageStripMetadata

    // Video
    @State private var videoQuality: Double = Double(OptimizationQualitySettings.videoQuality)
    @State private var videoEncoderPreset = OptimizationQualitySettings.videoEncoderPreset
    @State private var videoAudioBitrate = OptimizationQualitySettings.videoAudioBitrate

    // GIF
    @State private var gifsicleLevel: Double = Double(OptimizationQualitySettings.gifsicleOptimizationLevel)
    @State private var gifFrameRate: Double = Double(OptimizationQualitySettings.gifFrameRate)
    @State private var gifMaxWidth: Double = Double(OptimizationQualitySettings.gifMaxWidth)

    // PDF
    @State private var pdfPreset = OptimizationQualitySettings.pdfPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                workspaceSectionLabel("Quality")
                Spacer()
            }

            Picker("", selection: $selectedFormat) {
                ForEach(QualityFormatType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 8) {
                switch selectedFormat {
                case .images:
                    imagesControls
                case .video:
                    videoControls
                case .gif:
                    gifControls
                case .pdf:
                    pdfControls
                }
            }
            .padding(.top, 4)
        }
        .onAppear {
            autoDetectFormat()
        }
        .onChange(of: quickAccess.items.map { $0.id }) { _ in
            autoDetectFormat()
        }
    }

    private func autoDetectFormat() {
        let activeItems = quickAccess.items.filter { $0.state == .staged || $0.state == .queued || $0.state == .processing }
        guard let latestItem = activeItems.last else { return }

        if !autoDetectedIds.contains(latestItem.id) {
            autoDetectedIds.insert(latestItem.id)
            withAnimation(.easeInOut(duration: 0.2)) {
                switch latestItem.kind {
                case .png, .jpeg, .image:
                    selectedFormat = .images
                case .video:
                    selectedFormat = .video
                case .gif:
                    selectedFormat = .gif
                case .pdf:
                    selectedFormat = .pdf
                case .unknown:
                    break
                }
            }
        }
    }

    // MARK: - Images

    private var imagesControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceConfigRow(title: "Quality") {
                HStack(spacing: 8) {
                    Slider(value: $imageQuality, in: 10...100)
                        .frame(width: 100)
                        .onChange(of: imageQuality) { newValue in
                            let rounded = round(newValue / 5.0) * 5.0
                            if rounded != imageQuality {
                                imageQuality = rounded
                            }
                            OptimizationQualitySettings.imageQuality = Int(rounded)
                        }
                    WorkspaceValueReadout(value: Int(imageQuality))
                }
            }

            WorkspaceConfigRow(title: "Max Width") {
                HStack(spacing: 8) {
                    Slider(value: $imageMaxWidth, in: 512...8192)
                        .frame(width: 100)
                        .onChange(of: imageMaxWidth) { newValue in
                            let rounded = (round(newValue / 64.0) * 64.0)
                            if rounded != imageMaxWidth {
                                imageMaxWidth = rounded
                            }
                            OptimizationQualitySettings.imageMaxWidth = Int(rounded)
                        }
                    Text("\(Int(imageMaxWidth))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            WorkspaceConfigRow(title: "Strip Metadata") {
                Toggle("", isOn: $imageStripMetadata)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .onChange(of: imageStripMetadata) { newValue in
                        OptimizationQualitySettings.imageStripMetadata = newValue
                    }
            }
        }
    }

    // MARK: - Video

    private var videoControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceConfigRow(title: "Quality (CRF)") {
                HStack(spacing: 8) {
                    Slider(value: $videoQuality, in: 18...51)
                        .frame(width: 100)
                        .onChange(of: videoQuality) { newValue in
                            let rounded = round(newValue)
                            if rounded != videoQuality {
                                videoQuality = rounded
                            }
                            OptimizationQualitySettings.videoQuality = Int(rounded)
                        }
                    WorkspaceValueReadout(value: Int(videoQuality))
                }
            }

            WorkspaceConfigRow(title: "Encoder") {
                Picker("", selection: $videoEncoderPreset) {
                    ForEach(FFmpegPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150, alignment: .trailing)
                .onChange(of: videoEncoderPreset) { newValue in
                    OptimizationQualitySettings.videoEncoderPreset = newValue
                }
            }

            WorkspaceConfigRow(title: "Audio") {
                Picker("", selection: $videoAudioBitrate) {
                    ForEach(VideoAudioBitrate.allCases) { bitrate in
                        Text(bitrate.displayName).tag(bitrate)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150, alignment: .trailing)
                .onChange(of: videoAudioBitrate) { newValue in
                    OptimizationQualitySettings.videoAudioBitrate = newValue
                }
            }
        }
    }

    // MARK: - GIF

    private var gifControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceConfigRow(title: "Opt Level") {
                HStack(spacing: 8) {
                    Slider(value: $gifsicleLevel, in: 1...3)
                        .frame(width: 100)
                        .onChange(of: gifsicleLevel) { newValue in
                            let rounded = round(newValue)
                            if rounded != gifsicleLevel {
                                gifsicleLevel = rounded
                            }
                            OptimizationQualitySettings.gifsicleOptimizationLevel = Int(rounded)
                        }
                    WorkspaceValueReadout(value: Int(gifsicleLevel))
                }
            }

            WorkspaceConfigRow(title: "Frame Rate") {
                HStack(spacing: 8) {
                    Slider(value: $gifFrameRate, in: 5...30)
                        .frame(width: 100)
                        .onChange(of: gifFrameRate) { newValue in
                            let rounded = round(newValue)
                            if rounded != gifFrameRate {
                                gifFrameRate = rounded
                            }
                            OptimizationQualitySettings.gifFrameRate = Int(rounded)
                        }
                    Text("\(Int(gifFrameRate)) fps")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 48, alignment: .trailing)
                }
            }

            WorkspaceConfigRow(title: "Max Width") {
                HStack(spacing: 8) {
                    Slider(value: $gifMaxWidth, in: 240...1280)
                        .frame(width: 100)
                        .onChange(of: gifMaxWidth) { newValue in
                            let rounded = (round(newValue / 40.0) * 40.0)
                            if rounded != gifMaxWidth {
                                gifMaxWidth = rounded
                            }
                            OptimizationQualitySettings.gifMaxWidth = Int(rounded)
                        }
                    Text("\(Int(gifMaxWidth))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - PDF

    private var pdfControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkspaceConfigRow(title: "Preset") {
                Picker("", selection: $pdfPreset) {
                    ForEach(PDFPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150, alignment: .trailing)
                .onChange(of: pdfPreset) { newValue in
                    OptimizationQualitySettings.pdfPreset = newValue
                }
            }
        }
    }
}
