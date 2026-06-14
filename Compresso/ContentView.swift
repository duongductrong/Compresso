//
//  ContentView.swift
//  Compresso
//
//  Created by duongductrong on 17/5/26.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum CompressoSettingsWindowMetrics {
    static let minWidth: CGFloat = 860
    static let idealWidth: CGFloat = 860
    static let minHeight: CGFloat = 560
    static let idealHeight: CGFloat = 760
}

struct ContentView: View {
    @ObservedObject private var quickAccess = QuickAccessManager.shared
    @State private var selectedSection: CompressoSettingsSection? = .about
    @State private var searchText = ""
    @State private var isImporting = false

    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                CompressoModernSettingsRoot(
                    quickAccess: quickAccess,
                    selectedSection: $selectedSection,
                    selectedDetailSection: selectedSectionBinding,
                    searchText: $searchText,
                    isImporting: $isImporting
                )
            } else {
                CompressoLegacySettingsRoot(
                    quickAccess: quickAccess,
                    selectedSection: $selectedSection,
                    selectedDetailSection: selectedSectionBinding,
                    searchText: $searchText,
                    isImporting: $isImporting
                )
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: QuickAccessFileKind.importableContentTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                quickAccess.ingestDroppedURLs(urls)
            }
        }
        .onAppear {
            quickAccess.start()
        }
        .background(SettingsWindowConfigurator())
        .frame(
            minWidth: CompressoSettingsWindowMetrics.minWidth,
            idealWidth: CompressoSettingsWindowMetrics.idealWidth,
            maxWidth: .infinity,
            minHeight: CompressoSettingsWindowMetrics.minHeight,
            idealHeight: CompressoSettingsWindowMetrics.idealHeight,
            maxHeight: .infinity
        )
    }

    private var selectedSectionBinding: Binding<CompressoSettingsSection> {
        Binding(
            get: { (selectedSection ?? .about).canonicalSection },
            set: { selectedSection = $0.canonicalSection }
        )
    }

}

private struct SettingsWindowConfigurator: NSViewRepresentable {
    final class Coordinator {
        var configuredWindow: NSWindow?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        configureWindow(for: view, context: context)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configureWindow(for: nsView, context: context)
    }

    private func configureWindow(for view: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }

            window.minSize = NSSize(
                width: CompressoSettingsWindowMetrics.minWidth,
                height: CompressoSettingsWindowMetrics.minHeight
            )

            guard context.coordinator.configuredWindow !== window else { return }

            context.coordinator.configuredWindow = window
            window.setContentSize(
                NSSize(
                    width: CompressoSettingsWindowMetrics.idealWidth,
                    height: CompressoSettingsWindowMetrics.idealHeight
                )
            )
            window.center()
        }
    }
}

@available(macOS 13.0, *)
private struct CompressoModernSettingsRoot: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var selectedSection: CompressoSettingsSection?
    let selectedDetailSection: Binding<CompressoSettingsSection>
    @Binding var searchText: String
    @Binding var isImporting: Bool
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CompressoSettingsSidebarView(
                selection: $selectedSection,
                searchText: $searchText,
                toggleSidebar: toggleSidebar
            )
        } detail: {
            CompressoSettingsDetailView(
                selection: selectedDetailSection,
                quickAccess: quickAccess,
                isImporting: $isImporting
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .topLeading) {
            if columnVisibility == .detailOnly {
                collapsedSidebarChromeOverlay
            }
        }
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.18)) {
            columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
        }
    }

    private var sidebarToggleButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
                .compressoHierarchicalSymbolRendering()
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .help("Toggle Sidebar")
    }

    private var collapsedSidebarChrome: some View {
        HStack(spacing: 16) {
            CompressoTrafficLightsView()

            sidebarToggleButton
        }
    }

    private var collapsedSidebarChromeOverlay: some View {
        GeometryReader { proxy in
            collapsedSidebarChrome
                .padding(.top, 16)
                .padding(.leading, 18)
                .offset(y: -proxy.safeAreaInsets.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct CompressoLegacySettingsRoot: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var selectedSection: CompressoSettingsSection?
    let selectedDetailSection: Binding<CompressoSettingsSection>
    @Binding var searchText: String
    @Binding var isImporting: Bool
    @State private var isSidebarVisible = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                if isSidebarVisible {
                    CompressoSettingsSidebarView(
                        selection: $selectedSection,
                        searchText: $searchText,
                        toggleSidebar: toggleSidebar
                    )
                    .frame(width: CompressoSettingsSidebarMetrics.width)

                    Divider()
                }

                CompressoSettingsDetailView(
                    selection: selectedDetailSection,
                    quickAccess: quickAccess,
                    isImporting: $isImporting
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if !isSidebarVisible {
                collapsedSidebarChrome
                    .padding(.top, 16)
                    .padding(.leading, 18)
            }
        }
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isSidebarVisible.toggle()
        }
    }

    private var sidebarToggleButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
                .compressoHierarchicalSymbolRendering()
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .help("Toggle Sidebar")
    }

    private var collapsedSidebarChrome: some View {
        HStack(spacing: 16) {
            CompressoTrafficLightsView()

            sidebarToggleButton
        }
    }
}

#Preview {
    ContentView()
}
