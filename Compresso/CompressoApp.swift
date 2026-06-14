//
//  CompressoApp.swift
//  Compresso
//
//  Created by duongductrong on 17/5/26.
//

import AppKit
import SwiftUI

@main
struct CompressoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Compresso") {
            CompressoLaunchView()
                .background(WindowChromeConfigurator())
                .compressoHiddenWindowToolbar()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    UpdaterManager.shared.checkForUpdates()
                }
            }
        }
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        configureWindow(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        configureWindow(for: nsView)
    }

    private func configureWindow(for view: NSView) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.minSize = NSSize(width: 720, height: 520)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}
