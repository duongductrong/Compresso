//
//  CompressoWorkspaceViewStyle.swift
//  Compresso
//

import Foundation

// MARK: - View Style Setting

enum CompressoWorkspaceViewStyle: String, CaseIterable, Identifiable {
    case list
    case grid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .list: "List"
        case .grid: "Grid"
        }
    }

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .grid: "square.grid.2x2"
        }
    }

    private static let key = "workspace.viewStyle"

    static var current: CompressoWorkspaceViewStyle {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key) else {
                return .list
            }
            if raw == "stack" {
                return .grid
            }
            return CompressoWorkspaceViewStyle(rawValue: raw) ?? .list
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}
