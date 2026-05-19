//
//  DroplitApp.swift
//  Droplit
//
//  Created by duongductrong on 17/5/26.
//

import AppKit
import SwiftUI

@main
struct DroplitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Droplit", id: "main") {
            DroplitLaunchView()
                .background(WindowChromeConfigurator())
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .toolbarVisibility(.hidden, for: .windowToolbar)
        }
        .defaultSize(width: 920, height: 680)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .windowStyle(.hiddenTitleBar)
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
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}
