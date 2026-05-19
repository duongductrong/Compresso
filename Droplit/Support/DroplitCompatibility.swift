import AppKit
import SwiftUI

enum DroplitMaterialKind {
    case ultraThin
    case regular
}

struct DroplitMaterialFill<S: Shape>: View {
    let shape: S
    let kind: DroplitMaterialKind
    let fallbackOpacity: Double

    var body: some View {
        if #available(macOS 12.0, *) {
            switch kind {
            case .ultraThin:
                shape.fill(.ultraThinMaterial)
            case .regular:
                shape.fill(.regularMaterial)
            }
        } else {
            shape.fill(DroplitCompatibility.materialFallbackColor.opacity(fallbackOpacity))
        }
    }
}

struct DroplitWindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool {
            true
        }
    }
}

struct DroplitEmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(description)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 320)
        .padding()
    }
}

enum DroplitCompatibility {
    static var materialFallbackColor: Color {
        Color(NSColor.windowBackgroundColor)
    }

    static var controlFallbackColor: Color {
        Color(NSColor.controlBackgroundColor)
    }

    static var separatorColor: Color {
        Color(NSColor.separatorColor)
    }
}

private struct DroplitTaskModifier<ID: Equatable>: ViewModifier {
    let id: ID
    let priority: TaskPriority
    let action: @Sendable () async -> Void
    @State private var task: Task<Void, Never>?

    func body(content: Content) -> some View {
        if #available(macOS 12.0, *) {
            content.task(id: id, priority: priority) {
                await action()
            }
        } else {
            content
                .onAppear {
                    restartTask()
                }
                .onChange(of: id) { _ in
                    restartTask()
                }
                .onDisappear {
                    task?.cancel()
                    task = nil
                }
        }
    }

    private func restartTask() {
        task?.cancel()
        task = Task(priority: priority) {
            await action()
        }
    }
}

extension View {
    @ViewBuilder
    func droplitMaterialBackground<S: Shape>(
        _ kind: DroplitMaterialKind,
        in shape: S,
        fallbackOpacity: Double = 0.82
    ) -> some View {
        if #available(macOS 12.0, *) {
            switch kind {
            case .ultraThin:
                background(.ultraThinMaterial, in: shape)
            case .regular:
                background(.regularMaterial, in: shape)
            }
        } else {
            background(shape.fill(DroplitCompatibility.controlFallbackColor.opacity(fallbackOpacity)))
        }
    }

    @ViewBuilder
    func droplitMonospacedDigit() -> some View {
        if #available(macOS 12.0, *) {
            monospacedDigit()
        } else {
            self
        }
    }

    @ViewBuilder
    func droplitHierarchicalSymbolRendering() -> some View {
        if #available(macOS 12.0, *) {
            symbolRenderingMode(.hierarchical)
        } else {
            self
        }
    }

    @ViewBuilder
    func droplitTextSelectionEnabled() -> some View {
        if #available(macOS 12.0, *) {
            textSelection(.enabled)
        } else {
            self
        }
    }

    @ViewBuilder
    func droplitProminentButtonStyle() -> some View {
        if #available(macOS 12.0, *) {
            buttonStyle(.borderedProminent)
        } else {
            self
        }
    }

    @ViewBuilder
    func droplitScrollBounceBasedOnSize() -> some View {
        if #available(macOS 13.3, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    @ViewBuilder
    func droplitWindowMaterialBackground() -> some View {
        if #available(macOS 15.0, *) {
            containerBackground(.ultraThinMaterial, for: .window)
        } else {
            background(DroplitCompatibility.materialFallbackColor.opacity(0.68).ignoresSafeArea())
        }
    }

    @ViewBuilder
    func droplitHiddenWindowToolbar() -> some View {
        if #available(macOS 15.0, *) {
            toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .toolbarVisibility(.hidden, for: .windowToolbar)
        } else {
            self
        }
    }

    @ViewBuilder
    func droplitSidebarColumnWidth(min: CGFloat, ideal: CGFloat, max: CGFloat) -> some View {
        if #available(macOS 13.0, *) {
            navigationSplitViewColumnWidth(min: min, ideal: ideal, max: max)
        } else {
            frame(minWidth: min, idealWidth: ideal, maxWidth: max)
        }
    }

    func droplitTask<ID: Equatable>(
        id: ID,
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(DroplitTaskModifier(id: id, priority: priority, action: action))
    }
}
