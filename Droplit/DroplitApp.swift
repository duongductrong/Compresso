//
//  DroplitApp.swift
//  Droplit
//
//  Created by duongductrong on 17/5/26.
//

import SwiftUI

@main
struct DroplitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)

        Settings {
            EmptyView()
                .frame(width: 0, height: 0)
        }
    }
}
