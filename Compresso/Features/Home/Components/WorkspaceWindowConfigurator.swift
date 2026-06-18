//
//  WorkspaceWindowConfigurator.swift
//  Compresso
//

import AppKit
import SwiftUI

// MARK: - Window Configurator

struct WorkspaceWindowConfigurator: NSViewRepresentable {
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
                width: CompressoWorkspaceMetrics.minWidth,
                height: CompressoWorkspaceMetrics.minHeight
            )

            // Transparency & Vibrancy configuration
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)

            // Force traffic lights to be visible
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false

            guard context.coordinator.configuredWindow !== window else { return }

            context.coordinator.configuredWindow = window
            window.setContentSize(
                NSSize(
                    width: CompressoWorkspaceMetrics.idealWidth,
                    height: CompressoWorkspaceMetrics.idealHeight
                )
            )
            window.center()
        }
    }
}
