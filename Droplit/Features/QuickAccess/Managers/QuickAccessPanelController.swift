import AppKit
import SwiftUI

@MainActor
final class QuickAccessPanelController {
    private var panel: QuickAccessPanel?
    private var position: QuickAccessPosition = .bottomRight
    private let padding: CGFloat = 22
    private var isAnimating = false
    private var activeContentHeight: CGFloat = 0
    private var shadowMargin: CGFloat = QuickAccessLayout.shadowMargin

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    var isVisible: Bool { panel != nil }

    func show<Content: View>(
        _ content: Content,
        size: CGSize,
        position: QuickAccessPosition,
        activeContentHeight: CGFloat,
        shadowMargin: CGFloat
    ) {
        guard !isAnimating else { return }
        self.position = position
        self.activeContentHeight = activeContentHeight
        self.shadowMargin = shadowMargin

        let screen = ScreenUtility.activeScreen()
        let targetOrigin = position.calculateOrigin(
            for: size,
            on: screen,
            padding: padding,
            shadowMargin: shadowMargin
        )
        let targetFrame = NSRect(origin: targetOrigin, size: size)

        let panel = QuickAccessPanel(contentRect: targetFrame)
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: size)
        panel.contentView = hostingView
        panel.updatePassthroughRegion(activeContentHeight: activeContentHeight, edge: position.edge)
        self.panel = panel

        if reduceMotion {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = QuickAccessAnimations.panelExitDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1
            }
        } else {
            let offscreenOrigin = position.offscreenOrigin(
                for: size,
                on: screen,
                padding: padding,
                shadowMargin: shadowMargin
            )
            panel.setFrame(NSRect(origin: offscreenOrigin, size: size), display: false)
            panel.alphaValue = 1
            panel.orderFrontRegardless()

            isAnimating = true
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = QuickAccessAnimations.panelEnterDuration
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1.0, 0.36, 1.0)
                panel.animator().setFrame(targetFrame, display: true)
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    panel.updatePassthroughRegion(
                        activeContentHeight: self?.activeContentHeight ?? 0,
                        edge: self?.position.edge ?? .bottom
                    )
                    self?.isAnimating = false
                }
            })
        }
    }

    func updatePosition(_ newPosition: QuickAccessPosition) {
        position = newPosition
        panel?.updatePassthroughRegion(activeContentHeight: activeContentHeight, edge: newPosition.edge)
        repositionPanel()
    }

    func updateSize(_ size: CGSize, shadowMargin: CGFloat) {
        guard let panel, !isAnimating else { return }
        self.shadowMargin = shadowMargin
        let screen = ScreenUtility.activeScreen()
        let origin = position.calculateOrigin(
            for: size,
            on: screen,
            padding: padding,
            shadowMargin: shadowMargin
        )
        let targetFrame = NSRect(origin: origin, size: size)
        if panel.frame != targetFrame {
            panel.setFrame(targetFrame, display: true, animate: false)
        }
        panel.updatePassthroughRegion(activeContentHeight: activeContentHeight, edge: position.edge)
    }

    func updateInteractionMetrics(activeContentHeight: CGFloat) {
        self.activeContentHeight = activeContentHeight
        panel?.updatePassthroughRegion(activeContentHeight: activeContentHeight, edge: position.edge)
    }

    func hide() {
        guard let panel, !isAnimating else { return }

        if reduceMotion {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = QuickAccessAnimations.panelExitDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                panel.close()
                MainActor.assumeIsolated {
                    self?.panel = nil
                }
            })
        } else {
            let screen = ScreenUtility.activeScreen()
            let size = panel.frame.size
            let offscreenOrigin = position.offscreenOrigin(
                for: size,
                on: screen,
                padding: padding,
                shadowMargin: shadowMargin
            )
            isAnimating = true
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = QuickAccessAnimations.panelExitDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(NSRect(origin: offscreenOrigin, size: size), display: true)
                panel.animator().alphaValue = 0.5
            }, completionHandler: { [weak self] in
                panel.close()
                MainActor.assumeIsolated {
                    self?.panel = nil
                    self?.isAnimating = false
                }
            })
        }
    }

    private func repositionPanel() {
        guard let panel, !isAnimating else { return }
        let screen = ScreenUtility.activeScreen()
        let origin = position.calculateOrigin(
            for: panel.frame.size,
            on: screen,
            padding: padding,
            shadowMargin: shadowMargin
        )

        if reduceMotion {
            panel.setFrameOrigin(origin)
            panel.updatePassthroughRegion(activeContentHeight: activeContentHeight, edge: position.edge)
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrameOrigin(origin)
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    panel.updatePassthroughRegion(
                        activeContentHeight: self?.activeContentHeight ?? 0,
                        edge: self?.position.edge ?? .bottom
                    )
                }
            })
        }
    }
}
