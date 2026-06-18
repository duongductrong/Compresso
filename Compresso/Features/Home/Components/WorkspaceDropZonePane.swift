//
//  WorkspaceDropZonePane.swift
//  Compresso
//
//  Left pane: empty-state drop zone or the populated file list/grid,
//  plus the floating view-style picker and sidebar-show toggle.
//

import SwiftUI

struct WorkspaceDropZonePane: View {
    @ObservedObject var quickAccess: QuickAccessManager
    @Binding var viewStyle: CompressoWorkspaceViewStyle
    @Binding var isImporting: Bool
    @Binding var isDropTargeted: Bool
    let isSidebarCollapsed: Bool
    let toggleSidebar: () -> Void

    var body: some View {
        ZStack {
            QuickAccessDropReceiverView(isTargeted: $isDropTargeted, movesWindowOnMouseDown: false) { urls in
                quickAccess.stageDroppedURLs(urls)
            }

            if quickAccess.items.isEmpty {
                emptyDropZone
            } else {
                populatedFileList
            }
        }
        .overlay(
            floatingControlGroup
                .padding(.top, 8)
                .padding(.trailing, 16),
            alignment: .topTrailing
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Floating Controls

    private var floatingViewStylePicker: some View {
        HStack(spacing: 2) {
            ForEach(CompressoWorkspaceViewStyle.allCases) { style in
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        viewStyle = style
                        CompressoWorkspaceViewStyle.current = style
                    }
                } label: {
                    Image(systemName: style.systemImage)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(viewStyle == style ? .primary : .secondary.opacity(0.85))
                        .frame(width: 26, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(viewStyle == style ? Color.primary.opacity(0.12) : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(style.displayName + " View")
            }
        }
        .padding(3)
        .background(
            VisualEffectView(material: .titlebar, blendingMode: .withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 1.5)
    }

    private var floatingControlGroup: some View {
        HStack(spacing: 8) {
            floatingViewStylePicker

            if isSidebarCollapsed {
                Button {
                    toggleSidebar()
                } label: {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .help("Show Configuration Sidebar (Cmd+Shift+B)")
            }
        }
    }

    // MARK: - Empty State

    private var emptyDropZone: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                    )
                    .foregroundColor(isDropTargeted ? .accentColor : .secondary.opacity(0.4))

                VStack(spacing: 14) {
                    Image(systemName: isDropTargeted ? "tray.full.fill" : "tray.and.arrow.down.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(isDropTargeted ? .accentColor : .secondary)
                        .scaleEffect(isDropTargeted ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDropTargeted)

                    VStack(spacing: 4) {
                        Text(isDropTargeted ? "Release to optimize" : "Drop files here")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDropTargeted ? .primary : .secondary)

                        Text("Images, videos, GIFs, and PDFs")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: 280, maxHeight: 200)

            Button {
                isImporting = true
            } label: {
                Label("Choose Files", systemImage: "plus.circle.fill")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderless)
            .foregroundColor(.accentColor)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Populated

    private var populatedFileList: some View {
        VStack(spacing: 0) {
            if viewStyle == .list {
                fileListView
            } else {
                fileGridView
            }

            compactDropHeader
        }
    }

    private var compactDropHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Info label (no icon)
                Text(isDropTargeted ? "Release to add files" : "\(quickAccess.items.count) " + (quickAccess.items.count == 1 ? "file" : "files") + " in queue")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isDropTargeted ? .accentColor : .secondary)

                Spacer()

                // "Add Files" text-only button
                Button {
                    isImporting = true
                } label: {
                    Text("Add Files")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .help("Add files")

                // "Clear All" text-only button
                if !quickAccess.items.isEmpty {
                    Button {
                        quickAccess.removeAllItems()
                    } label: {
                        Text("Clear All")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.red.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Remove all files")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isDropTargeted
                    ? Color.accentColor.opacity(0.05)
                    : Color.clear
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
    }

    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(quickAccess.items) { item in
                    WorkspaceFileCell(
                        item: item,
                        style: .list,
                        onRemove: { quickAccess.removeItem(id: item.id) },
                        onOpen: { quickAccess.openItem(for: item.id) },
                        onReveal: { quickAccess.revealOutput(for: item.id) }
                    )
                }
            }
            .padding(.top, 48)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .compressoScrollBounceBasedOnSize()
    }

    private var fileGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)], spacing: 14) {
                ForEach(quickAccess.items) { item in
                    WorkspaceFileCell(
                        item: item,
                        style: .grid,
                        onRemove: { quickAccess.removeItem(id: item.id) },
                        onOpen: { quickAccess.openItem(for: item.id) },
                        onReveal: { quickAccess.revealOutput(for: item.id) }
                    )
                }
            }
            .padding(.top, 48)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .compressoScrollBounceBasedOnSize()
    }
}
