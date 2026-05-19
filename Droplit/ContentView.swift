//
//  ContentView.swift
//  Droplit
//
//  Created by duongductrong on 17/5/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject private var quickAccess = QuickAccessManager.shared
    @State private var selectedSection: DroplitSettingsSection? = .about
    @State private var searchText = ""
    @State private var isImporting = false

    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                DroplitModernSettingsRoot(
                    quickAccess: quickAccess,
                    selectedSection: $selectedSection,
                    selectedDetailSection: selectedSectionBinding,
                    searchText: $searchText,
                    isImporting: $isImporting
                )
            } else {
                DroplitLegacySettingsRoot(
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
    }

    private var selectedSectionBinding: Binding<DroplitSettingsSection> {
        Binding(
            get: { (selectedSection ?? .about).canonicalSection },
            set: { selectedSection = $0.canonicalSection }
        )
    }

}

@available(macOS 13.0, *)
private struct DroplitModernSettingsRoot: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var selectedSection: DroplitSettingsSection?
    let selectedDetailSection: Binding<DroplitSettingsSection>
    @Binding var searchText: String
    @Binding var isImporting: Bool
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            DroplitSettingsSidebarView(
                selection: $selectedSection,
                searchText: $searchText,
                toggleSidebar: toggleSidebar
            )
        } detail: {
            DroplitSettingsDetailView(
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
                .droplitHierarchicalSymbolRendering()
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .help("Toggle Sidebar")
    }

    private var collapsedSidebarChrome: some View {
        HStack(spacing: 16) {
            DroplitTrafficLightsView()

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

private struct DroplitLegacySettingsRoot: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var selectedSection: DroplitSettingsSection?
    let selectedDetailSection: Binding<DroplitSettingsSection>
    @Binding var searchText: String
    @Binding var isImporting: Bool
    @State private var isSidebarVisible = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                if isSidebarVisible {
                    DroplitSettingsSidebarView(
                        selection: $selectedSection,
                        searchText: $searchText,
                        toggleSidebar: toggleSidebar
                    )
                    .frame(width: 250)

                    Divider()
                }

                DroplitSettingsDetailView(
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
                .droplitHierarchicalSymbolRendering()
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.borderless)
        .help("Toggle Sidebar")
    }

    private var collapsedSidebarChrome: some View {
        HStack(spacing: 16) {
            DroplitTrafficLightsView()

            sidebarToggleButton
        }
    }
}

#Preview {
    ContentView()
}
