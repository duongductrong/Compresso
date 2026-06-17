import AppKit
import SwiftUI
import ObjectiveC


enum CompressoMaterialKind {
    case ultraThin
    case regular
}

struct CompressoMaterialFill<S: Shape>: View {
    let shape: S
    let kind: CompressoMaterialKind
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
            shape.fill(CompressoCompatibility.materialFallbackColor.opacity(fallbackOpacity))
        }
    }
}

struct CompressoWindowDragArea: NSViewRepresentable {
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

struct CompressoEmptyStateView: View {
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

enum CompressoCompatibility {
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

private struct CompressoTaskModifier<ID: Equatable>: ViewModifier {
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
    func compressoMaterialBackground<S: Shape>(
        _ kind: CompressoMaterialKind,
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
            background(shape.fill(CompressoCompatibility.controlFallbackColor.opacity(fallbackOpacity)))
        }
    }

    @ViewBuilder
    func compressoMonospacedDigit() -> some View {
        if #available(macOS 12.0, *) {
            monospacedDigit()
        } else {
            self
        }
    }

    @ViewBuilder
    func compressoHierarchicalSymbolRendering() -> some View {
        if #available(macOS 12.0, *) {
            symbolRenderingMode(.hierarchical)
        } else {
            self
        }
    }

    @ViewBuilder
    func compressoTextSelectionEnabled() -> some View {
        if #available(macOS 12.0, *) {
            textSelection(.enabled)
        } else {
            self
        }
    }

    @ViewBuilder
    func compressoProminentButtonStyle() -> some View {
        if #available(macOS 12.0, *) {
            buttonStyle(.borderedProminent)
        } else {
            self
        }
    }

    @ViewBuilder
    func compressoScrollBounceBasedOnSize() -> some View {
        if #available(macOS 13.3, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

    @ViewBuilder
    func compressoWindowMaterialBackground() -> some View {
        if #available(macOS 15.0, *) {
            containerBackground(.ultraThinMaterial, for: .window)
        } else {
            background(CompressoCompatibility.materialFallbackColor.opacity(0.68).ignoresSafeArea())
        }
    }

    @ViewBuilder
    func compressoHiddenWindowToolbar() -> some View {
        if #available(macOS 15.0, *) {
            toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            self
        }
    }

    @ViewBuilder
    func compressoSidebarColumnWidth(min: CGFloat, ideal: CGFloat, max: CGFloat) -> some View {
        if #available(macOS 13.0, *) {
            navigationSplitViewColumnWidth(min: min, ideal: ideal, max: max)
        } else {
            frame(minWidth: min, idealWidth: ideal, maxWidth: max)
        }
    }

    func compressoTask<ID: Equatable>(
        id: ID,
        priority: TaskPriority = .userInitiated,
        _ action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(CompressoTaskModifier(id: id, priority: priority, action: action))
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

struct SplitViewDividerConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = ConfiguratorView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfiguratorView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureParentSplitView()
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            configureParentSplitView()
        }

        private func configureParentSplitView() {
            var current: NSView? = self
            while let view = current {
                if let splitView = view as? NSSplitView {
                    setupCustomSplitView(splitView)
                    return
                }
                current = view.superview
            }
        }

        private func setupCustomSplitView(_ splitView: NSSplitView) {
            guard let clazz = object_getClass(splitView) else { return }

            let selector = #selector(NSSplitView.drawDivider(in:))
            guard let method = class_getInstanceMethod(clazz, selector) else { return }

            // Create a block that matches the method signature: (self, rect) -> Void
            let drawDividerBlock: @convention(block) (AnyObject, NSRect) -> Void = { _, rect in
                let color = NSColor(name: nil) { appearance in
                    if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                        return NSColor(white: 0.28, alpha: 1.0)
                    } else {
                        return NSColor(white: 0.82, alpha: 1.0)
                    }
                }
                color.setFill()
                rect.fill()
            }

            let imp = imp_implementationWithBlock(drawDividerBlock)
            class_replaceMethod(clazz, selector, imp, method_getTypeEncoding(method))

            splitView.needsDisplay = true
        }
    }
}

