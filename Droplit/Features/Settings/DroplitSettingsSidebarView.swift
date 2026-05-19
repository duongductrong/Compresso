import AppKit
import SwiftUI

struct DroplitSettingsSidebarView: View {
    @Binding var selection: DroplitSettingsSection?
    @Binding var searchText: String
    let toggleSidebar: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader

            List(selection: canonicalSelection) {
                ForEach(filteredStandaloneSections) { section in
                    sidebarRow(section)
                        .tag(section as DroplitSettingsSection?)
                }

                ForEach(filteredGroups) { group in
                    Section {
                        ForEach(group.sections) { section in
                            sidebarRow(section)
                                .tag(section as DroplitSettingsSection?)
                        }
                    } header: {
                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                    }
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if !hasFilteredResults {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 280)
    }

    private var sidebarHeader: some View {
        VStack(spacing: 10) {
            sidebarChrome

            sidebarSearchField
        }
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var sidebarChrome: some View {
        HStack(alignment: .center, spacing: 0) {
            DroplitTrafficLightsView()

            Spacer(minLength: 12)

            Button(action: toggleSidebar) {
                Image(systemName: "sidebar.left")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Toggle Sidebar")
        }
        .frame(height: 24)
        .padding(.leading, 18)
        .padding(.trailing, 16)
    }

    private var sidebarSearchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search Settings", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Clear Search")
            }
        }
        .frame(height: 34)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.76))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .padding(.horizontal, 16)
    }

    private var filteredGroups: [DroplitSettingsSidebarGroup] {
        DroplitSettingsSection.sidebarGroups
            .compactMap { group in
                let filteredSections = group.sections.filter { $0.matches(searchText) }
                guard !filteredSections.isEmpty else { return nil }
                return DroplitSettingsSidebarGroup(
                    title: group.title,
                    sections: filteredSections
                )
            }
    }

    private var filteredStandaloneSections: [DroplitSettingsSection] {
        DroplitSettingsSection.standaloneSections.filter { $0.matches(searchText) }
    }

    private var hasFilteredResults: Bool {
        !filteredStandaloneSections.isEmpty || !filteredGroups.isEmpty
    }

    private var canonicalSelection: Binding<DroplitSettingsSection?> {
        Binding(
            get: { selection?.canonicalSection },
            set: { selection = $0?.canonicalSection }
        )
    }

    private func sidebarRow(_ section: DroplitSettingsSection) -> some View {
        HStack(spacing: 10) {
            Image(systemName: section.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .lineLimit(1)

                Text(section.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

struct DroplitTrafficLightsView: View {
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            trafficLight(color: Color(red: 1.0, green: 0.32, blue: 0.31), symbol: "xmark") {
                activeWindow?.performClose(nil)
            }

            trafficLight(color: Color(red: 1.0, green: 0.78, blue: 0.20), symbol: "minus") {
                activeWindow?.miniaturize(nil)
            }

            trafficLight(color: Color(red: 0.20, green: 0.80, blue: 0.32), symbol: "plus") {
                activeWindow?.zoom(nil)
            }
        }
        .onHover { isHovering = $0 }
        .help("Window Controls")
    }

    private func trafficLight(color: Color, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 13, height: 13)
                .overlay {
                    if isHovering {
                        Image(systemName: symbol)
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.black.opacity(0.55))
                    }
                }
                .overlay {
                    Circle()
                        .stroke(.black.opacity(0.16), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
    }

    private var activeWindow: NSWindow? {
        NSApp.keyWindow ?? NSApp.mainWindow
    }
}
