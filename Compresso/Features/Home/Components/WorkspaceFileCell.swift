//
//  WorkspaceFileCell.swift
//  Compresso
//
//  Unified file cell for the workspace drop zone. Renders in either a list
//  (short, full-width) or grid (taller, fixed column) layout.
//

import AppKit
import SwiftUI

struct WorkspaceFileCell: View {
    enum Style {
        case list
        case grid

        var height: CGFloat {
            switch self {
            case .list: 100
            case .grid: 140
            }
        }

        var titleFontSize: CGFloat {
            switch self {
            case .list: 12
            case .grid: 11
            }
        }

        var detailFontSize: CGFloat {
            switch self {
            case .list: 10
            case .grid: 9
            }
        }

        var horizontalContentPadding: CGFloat {
            switch self {
            case .list: 12
            case .grid: 10
            }
        }
    }

    let item: QuickAccessItem
    let style: Style
    let onRemove: () -> Void
    let onOpen: () -> Void
    let onReveal: () -> Void

    @State private var isHovering = false
    @State private var isDragging = false
    @State private var isHoveringRemove = false

    var body: some View {
        ZStack {
            Image(nsImage: item.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: style.height)
                .scaleEffect(isHovering ? 1.03 : 1.0)
                .blur(radius: isHovering ? 1.5 : 0)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    // Top-left file type badge (text badge instead of icon, avoiding icon overuse)
                    Text(item.sourceURL.pathExtension.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.black.opacity(0.6))
                        )

                    Spacer()

                    // Top-right close/remove button on hover
                    if isHovering {
                        Button {
                            onRemove()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(isHoveringRemove ? Color.black.opacity(0.8) : Color.black.opacity(0.5))
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { isHoveringRemove = $0 }
                    }
                }
                .padding(.horizontal, style.horizontalContentPadding)
                .padding(.top, 10)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.system(size: style.titleFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 8) {
                        Text(item.detailLine)
                            .font(.system(size: style.detailFontSize, weight: .semibold))
                            .foregroundColor(detailLineColor)
                            .lineLimit(1)

                        if isHovering && item.outputURL != nil {
                            Spacer()

                            Button("Reveal in Finder") {
                                onReveal()
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: style.detailFontSize, weight: .bold))
                            .foregroundColor(.accentColor)
                        }
                    }

                    if item.state == .processing {
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.25))
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: proxy.size.width * CGFloat(item.progress ?? 0.1))
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, style.horizontalContentPadding)
                .padding(.vertical, style == .list ? 10 : 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55), .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: style.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isHovering ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.12), lineWidth: isHovering ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(isHovering ? 0.16 : 0.08), radius: isHovering ? 8 : 4, x: 0, y: isHovering ? 4 : 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
        .onTapGesture(count: 2) {
            onOpen()
        }
        .contextMenu {
            Button("Open") { onOpen() }
            if item.outputURL != nil {
                Button("Reveal in Finder") { onReveal() }
            }
            Divider()
            Button("Remove") { onRemove() }
        }
        .gesture(externalDragGesture)
    }

    private var detailLineColor: Color {
        switch item.state {
        case .completed:
            return .green
        case .failed:
            return .red
        case .queued:
            return .orange
        default:
            return .white.opacity(0.85)
        }
    }

    private var externalDragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { _ in
                guard !isDragging else { return }
                guard let dragURL = item.preferredExternalDragURL else { return }
                isDragging = true
                _ = QuickAccessExternalDragSession.begin(
                    fileURL: dragURL,
                    thumbnail: item.thumbnail,
                    onEnded: { _ in
                        isDragging = false
                    }
                )
            }
    }
}
