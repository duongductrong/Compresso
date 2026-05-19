import AppKit
import SwiftUI

enum QuickAccessCursorStyle: Equatable {
    case pointingHand
    case closedHand

    var cursor: NSCursor {
        switch self {
        case .pointingHand:
            return .pointingHand
        case .closedHand:
            return .closedHand
        }
    }
}

private struct QuickAccessCursorModifier: ViewModifier {
    let style: QuickAccessCursorStyle
    @State private var activeStyle: QuickAccessCursorStyle?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if hovering {
                    push(style)
                } else {
                    pop()
                }
            }
            .onChange(of: style) { newStyle in
                guard activeStyle != nil else { return }
                pop()
                push(newStyle)
            }
            .onDisappear {
                pop()
            }
    }

    private func push(_ newStyle: QuickAccessCursorStyle) {
        guard activeStyle != newStyle else { return }
        if activeStyle != nil {
            NSCursor.pop()
        }
        newStyle.cursor.push()
        activeStyle = newStyle
    }

    private func pop() {
        guard activeStyle != nil else { return }
        NSCursor.pop()
        activeStyle = nil
    }
}

extension View {
    func quickAccessCursor(_ style: QuickAccessCursorStyle) -> some View {
        modifier(QuickAccessCursorModifier(style: style))
    }
}
