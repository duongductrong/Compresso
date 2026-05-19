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
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            DroplitSettingsSidebarView(
                selection: $selectedSection,
                searchText: $searchText,
                toggleSidebar: toggleSidebar
            )
        } detail: {
            ZStack(alignment: .topLeading) {
                DroplitSettingsDetailView(
                    selection: selectedSectionBinding,
                    quickAccess: quickAccess,
                    isImporting: $isImporting
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .topLeading) {
            if columnVisibility == .detailOnly {
                collapsedSidebarChromeOverlay
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

    private func toggleSidebar() {
        withAnimation(.snappy(duration: 0.18)) {
            columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
        }
    }

    private var sidebarToggleButton: some View {
        Button(action: toggleSidebar) {
            Image(systemName: "sidebar.left")
                .symbolRenderingMode(.hierarchical)
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

#Preview {
    ContentView()
}
