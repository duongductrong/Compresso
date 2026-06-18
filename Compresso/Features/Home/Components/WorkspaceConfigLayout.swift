//
//  WorkspaceConfigLayout.swift
//  Compresso
//
//  Shared layout primitives for the workspace configuration sidebar.
//  Used by both the output/watcher/capacity sections and the quality section.
//

import SwiftUI

// MARK: - Section Label

/// A small uppercase-style header used above each config section.
func workspaceSectionLabel(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.secondary)
}

// MARK: - Config Row

/// A standard label-leading, content-trailing row with consistent vertical rhythm.
struct WorkspaceConfigRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: true, vertical: false)

            Spacer()

            content
        }
        .frame(minHeight: 22)
    }
}

// MARK: - Value Readout

/// Monospaced trailing numeric readout used next to sliders.
struct WorkspaceValueReadout: View {
    let value: Int

    var body: some View {
        Text("\(value)")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary)
            .frame(width: 28, alignment: .trailing)
    }
}
