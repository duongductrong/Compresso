import SwiftUI

enum QuickAccessAnimations {
    static let panelEnterDuration: TimeInterval = 0.4
    static let panelExitDuration: TimeInterval = 0.25
    static let cardInsert = Animation.easeOut(duration: 0.25)
    static let cardRemove = Animation.spring(response: 0.25, dampingFraction: 0.82)
    static let progressPulse = Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true)
    static let hoverOverlay = Animation.easeOut(duration: 0.15)
}
